--
-- PostgreSQL database dump
--

\restrict 72gIr8jKbTZLfdHE1dxRnNsLMAXRD8bMiXg3OeO4awpfUkb9cuvq97B230SgUVq

-- Dumped from database version 17.9
-- Dumped by pg_dump version 17.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_despacho_actualiza_inventario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_despacho_actualiza_inventario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_almacen INTEGER;
  v_usuario INTEGER;
  v_id_pedido INTEGER;
  v_numero_despacho VARCHAR(40);
  v_stock_fisico NUMERIC(14,2);
  v_stock_reservado NUMERIC(14,2);
  v_reservado_pedido NUMERIC(14,2);
  v_costo NUMERIC(14,2);
BEGIN
  IF NEW.cantidad_entregada > 0 THEN
    SELECT
      d.id_almacen_salida,
      d.id_responsable_almacen,
      d.id_pedido,
      d.numero_despacho
    INTO v_almacen, v_usuario, v_id_pedido, v_numero_despacho
    FROM public.despachos d
    WHERE d.id_despacho = NEW.id_despacho;

    SELECT i.stock_fisico, i.stock_reservado, i.costo_promedio
    INTO v_stock_fisico, v_stock_reservado, v_costo
    FROM public.inventarios i
    WHERE i.id_insumo = NEW.id_insumo
      AND i.id_almacen = v_almacen
    FOR UPDATE;

    SELECT COALESCE(SUM(rs.cantidad_reservada), 0)
    INTO v_reservado_pedido
    FROM public.reservas_stock rs
    WHERE rs.id_pedido = v_id_pedido
      AND rs.id_insumo = NEW.id_insumo
      AND rs.id_almacen = v_almacen
      AND rs.estado = 'ACTIVA';

    IF COALESCE(v_stock_fisico, 0) < NEW.cantidad_entregada
       OR (
         v_reservado_pedido < NEW.cantidad_entregada
         AND COALESCE(v_stock_fisico, 0)
           - COALESCE(v_stock_reservado, 0) < NEW.cantidad_entregada
       ) THEN
      RAISE EXCEPTION
        'Stock insuficiente para el insumo %. Stock fisico: %, reservado para pedido: %, cantidad solicitada: %',
        NEW.id_insumo,
        COALESCE(v_stock_fisico, 0),
        COALESCE(v_reservado_pedido, 0),
        NEW.cantidad_entregada;
    END IF;

    UPDATE public.inventarios
    SET stock_fisico = stock_fisico - NEW.cantidad_entregada,
        estado_stock = CASE
          WHEN stock_fisico - NEW.cantidad_entregada = 0 THEN 'AGOTADO'
          WHEN stock_reservado > 0 THEN 'RESERVADO'
          ELSE 'DISPONIBLE'
        END,
        fecha_ultima_actualizacion = NOW(),
        actualizado_por = v_usuario
    WHERE id_insumo = NEW.id_insumo
      AND id_almacen = v_almacen;

    INSERT INTO public.movimientos_inventario (
      numero_movimiento,
      tipo_movimiento,
      id_insumo,
      id_almacen_origen,
      id_despacho,
      codigo_referencia,
      cantidad,
      costo_unitario,
      motivo,
      documento_respaldo,
      usuario_responsable,
      observaciones
    ) VALUES (
      'MOV-DES-' || NEW.id_despacho_detalle,
      'SALIDA_DESPACHO',
      NEW.id_insumo,
      v_almacen,
      NEW.id_despacho,
      v_numero_despacho,
      NEW.cantidad_entregada,
      COALESCE(v_costo, 0),
      'Salida automatica por despacho formal',
      v_numero_despacho,
      v_usuario,
      'Movimiento generado automaticamente desde despacho.'
    )
    ON CONFLICT (numero_movimiento) DO UPDATE
    SET id_despacho = EXCLUDED.id_despacho,
        codigo_referencia = EXCLUDED.codigo_referencia,
        documento_respaldo = COALESCE(
          public.movimientos_inventario.documento_respaldo,
          EXCLUDED.documento_respaldo
        ),
        id_almacen_origen = COALESCE(
          public.movimientos_inventario.id_almacen_origen,
          EXCLUDED.id_almacen_origen
        ),
        usuario_responsable = COALESCE(
          public.movimientos_inventario.usuario_responsable,
          EXCLUDED.usuario_responsable
        );
  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_despacho_actualiza_inventario() OWNER TO postgres;

--
-- Name: fn_recepcion_actualiza_inventario(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_recepcion_actualiza_inventario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_almacen INTEGER;
    v_usuario INTEGER;
    v_costo NUMERIC(14,2);
    v_numero_recepcion VARCHAR(40);
BEGIN
    IF NEW.cantidad_aceptada > 0 THEN
        SELECT rc.id_almacen_destino, rc.id_responsable_recepcion, rc.numero_recepcion
        INTO v_almacen, v_usuario, v_numero_recepcion
        FROM recepciones_compra rc
        WHERE rc.id_recepcion = NEW.id_recepcion;

        SELECT ocd.precio_unitario
        INTO v_costo
        FROM orden_compra_detalles ocd
        WHERE ocd.id_orden_detalle = NEW.id_orden_detalle;

        INSERT INTO inventarios (
            id_insumo, id_almacen, stock_fisico, stock_reservado,
            costo_promedio, fecha_ultima_actualizacion, creado_por
        )
        VALUES (
            NEW.id_insumo, v_almacen, NEW.cantidad_aceptada, 0,
            COALESCE(v_costo, 0), NOW(), v_usuario
        )
        ON CONFLICT (id_insumo, id_almacen)
        DO UPDATE SET
            costo_promedio = CASE
                WHEN (inventarios.stock_fisico + EXCLUDED.stock_fisico) > 0 THEN
                    ROUND(((inventarios.stock_fisico * inventarios.costo_promedio) +
                           (EXCLUDED.stock_fisico * EXCLUDED.costo_promedio)) /
                          (inventarios.stock_fisico + EXCLUDED.stock_fisico), 2)
                ELSE EXCLUDED.costo_promedio
            END,
            stock_fisico = inventarios.stock_fisico + EXCLUDED.stock_fisico,
            estado_stock = 'DISPONIBLE',
            fecha_ultima_actualizacion = NOW(),
            actualizado_por = v_usuario;

        INSERT INTO movimientos_inventario (
            numero_movimiento, tipo_movimiento, id_insumo, id_almacen_destino,
            cantidad, costo_unitario, motivo, documento_respaldo, usuario_responsable, observaciones
        )
        VALUES (
            'MOV-REC-' || NEW.id_recepcion_detalle,
            'ENTRADA_COMPRA',
            NEW.id_insumo,
            v_almacen,
            NEW.cantidad_aceptada,
            COALESCE(v_costo, 0),
            'Entrada automática por recepción de compra',
            v_numero_recepcion,
            v_usuario,
            'Movimiento generado automáticamente desde recepción de compra.'
        );
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_recepcion_actualiza_inventario() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: almacenes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.almacenes (
    id_almacen integer NOT NULL,
    codigo_almacen character varying(30) NOT NULL,
    nombre_almacen character varying(120) NOT NULL,
    tipo_almacen character varying(40) NOT NULL,
    ubicacion character varying(180) NOT NULL,
    id_responsable_principal integer,
    id_responsable_suplente integer,
    telefono_contacto character varying(30),
    horario_atencion character varying(120),
    descripcion text,
    capacidad_maxima numeric(14,2),
    capacidad_minima_recomendada numeric(14,2),
    tipo_almacenamiento character varying(120),
    observaciones_seguridad text,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    creado_por integer,
    actualizado_por integer,
    CONSTRAINT almacenes_capacidad_maxima_check CHECK (((capacidad_maxima IS NULL) OR (capacidad_maxima >= (0)::numeric))),
    CONSTRAINT almacenes_capacidad_minima_recomendada_check CHECK (((capacidad_minima_recomendada IS NULL) OR (capacidad_minima_recomendada >= (0)::numeric))),
    CONSTRAINT almacenes_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying, 'ELIMINADO'::character varying])::text[]))),
    CONSTRAINT almacenes_tipo_almacen_check CHECK (((tipo_almacen)::text = ANY ((ARRAY['SUPERFICIE'::character varying, 'SUBTERRANEO'::character varying, 'POLVORIN'::character varying, 'SEGURIDAD_INDUSTRIAL'::character varying, 'HERRAMIENTAS_REPUESTOS'::character varying, 'COMBUSTIBLE'::character varying, 'LUBRICANTES'::character varying, 'TEMPORAL'::character varying])::text[])))
);


ALTER TABLE public.almacenes OWNER TO postgres;

--
-- Name: almacenes_id_almacen_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.almacenes ALTER COLUMN id_almacen ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.almacenes_id_almacen_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: aprobaciones_pedido; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aprobaciones_pedido (
    id_aprobacion integer NOT NULL,
    id_pedido integer NOT NULL,
    id_usuario_aprobador integer NOT NULL,
    nivel_aprobacion integer DEFAULT 1 NOT NULL,
    fecha_aprobacion timestamp with time zone DEFAULT now() NOT NULL,
    estado_aprobacion character varying(30) NOT NULL,
    observaciones text,
    motivo_rechazo text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT aprobaciones_pedido_estado_aprobacion_check CHECK (((estado_aprobacion)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'APROBADO'::character varying, 'RECHAZADO'::character varying, 'OBSERVADO'::character varying])::text[]))),
    CONSTRAINT aprobaciones_pedido_nivel_aprobacion_check CHECK ((nivel_aprobacion >= 1))
);


ALTER TABLE public.aprobaciones_pedido OWNER TO postgres;

--
-- Name: aprobaciones_pedido_id_aprobacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.aprobaciones_pedido ALTER COLUMN id_aprobacion ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.aprobaciones_pedido_id_aprobacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: areas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.areas (
    id_area integer NOT NULL,
    nombre_area character varying(100) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    CONSTRAINT areas_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying])::text[])))
);


ALTER TABLE public.areas OWNER TO postgres;

--
-- Name: areas_id_area_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.areas ALTER COLUMN id_area ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.areas_id_area_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: auditorias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.auditorias (
    id_auditoria integer NOT NULL,
    id_usuario integer,
    accion_realizada character varying(150) NOT NULL,
    tipo_accion character varying(40) NOT NULL,
    modulo_afectado character varying(80) NOT NULL,
    tabla_afectada character varying(80),
    id_registro_afectado integer,
    registro_anterior jsonb,
    registro_nuevo jsonb,
    fecha_hora timestamp with time zone DEFAULT now() NOT NULL,
    direccion_ip character varying(60),
    navegador_dispositivo character varying(255),
    motivo_cambio text,
    observaciones text,
    CONSTRAINT auditorias_tipo_accion_check CHECK (((tipo_accion)::text = ANY ((ARRAY['CREAR'::character varying, 'EDITAR'::character varying, 'ELIMINAR'::character varying, 'ACTIVAR'::character varying, 'DESACTIVAR'::character varying, 'APROBAR'::character varying, 'RECHAZAR'::character varying, 'ANULAR'::character varying, 'LOGIN'::character varying, 'LOGOUT'::character varying, 'CONSULTAR'::character varying, 'REGISTRAR_COMPRA'::character varying, 'REGISTRAR_RECEPCION'::character varying, 'REGISTRAR_COMPROBANTE'::character varying, 'REALIZAR_DESPACHO'::character varying, 'AJUSTAR_INVENTARIO'::character varying, 'INICIAR_SESION'::character varying, 'CERRAR_SESION'::character varying, 'CAMBIAR_CONTRASENA'::character varying, 'CAMBIAR_PERMISOS'::character varying])::text[])))
);


ALTER TABLE public.auditorias OWNER TO postgres;

--
-- Name: auditorias_id_auditoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.auditorias ALTER COLUMN id_auditoria ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.auditorias_id_auditoria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: categorias_insumo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorias_insumo (
    id_categoria integer NOT NULL,
    nombre_categoria character varying(100) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    creado_por integer,
    CONSTRAINT categorias_insumo_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying])::text[])))
);


ALTER TABLE public.categorias_insumo OWNER TO postgres;

--
-- Name: categorias_insumo_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.categorias_insumo ALTER COLUMN id_categoria ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.categorias_insumo_id_categoria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: comprobantes_compra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comprobantes_compra (
    id_comprobante integer NOT NULL,
    numero_comprobante character varying(60) NOT NULL,
    tipo_comprobante character varying(40) NOT NULL,
    fecha_comprobante date DEFAULT CURRENT_DATE NOT NULL,
    id_proveedor integer NOT NULL,
    nit_proveedor character varying(30) NOT NULL,
    id_orden_compra integer NOT NULL,
    monto_subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    monto_descuento numeric(14,2) DEFAULT 0 NOT NULL,
    monto_impuesto numeric(14,2) DEFAULT 0 NOT NULL,
    monto_total numeric(14,2) GENERATED ALWAYS AS (((monto_subtotal - monto_descuento) + monto_impuesto)) STORED,
    moneda character varying(10) DEFAULT 'BOB'::character varying NOT NULL,
    estado_comprobante character varying(30) DEFAULT 'REGISTRADO'::character varying NOT NULL,
    archivo_comprobante character varying(255),
    observaciones text,
    usuario_registra integer,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT comprobantes_compra_estado_comprobante_check CHECK (((estado_comprobante)::text = ANY ((ARRAY['REGISTRADO'::character varying, 'OBSERVADO'::character varying, 'ANULADO'::character varying])::text[]))),
    CONSTRAINT comprobantes_compra_monto_descuento_check CHECK ((monto_descuento >= (0)::numeric)),
    CONSTRAINT comprobantes_compra_monto_impuesto_check CHECK ((monto_impuesto >= (0)::numeric)),
    CONSTRAINT comprobantes_compra_monto_subtotal_check CHECK ((monto_subtotal >= (0)::numeric)),
    CONSTRAINT comprobantes_compra_tipo_comprobante_check CHECK (((tipo_comprobante)::text = ANY ((ARRAY['FACTURA'::character varying, 'RECIBO'::character varying, 'NOTA_VENTA'::character varying, 'COMPROBANTE_INTERNO'::character varying, 'OTRO'::character varying])::text[])))
);


ALTER TABLE public.comprobantes_compra OWNER TO postgres;

--
-- Name: comprobantes_compra_id_comprobante_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.comprobantes_compra ALTER COLUMN id_comprobante ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.comprobantes_compra_id_comprobante_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: despacho_detalles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.despacho_detalles (
    id_despacho_detalle integer NOT NULL,
    id_despacho integer NOT NULL,
    id_insumo integer NOT NULL,
    cantidad_solicitada numeric(14,2) NOT NULL,
    cantidad_aprobada numeric(14,2) NOT NULL,
    cantidad_entregada numeric(14,2) NOT NULL,
    cantidad_pendiente numeric(14,2) GENERATED ALWAYS AS ((cantidad_aprobada - cantidad_entregada)) STORED,
    estado_conformidad character varying(30) NOT NULL,
    observacion text,
    CONSTRAINT despacho_detalles_cantidad_aprobada_check CHECK ((cantidad_aprobada >= (0)::numeric)),
    CONSTRAINT despacho_detalles_cantidad_entregada_check CHECK ((cantidad_entregada >= (0)::numeric)),
    CONSTRAINT despacho_detalles_cantidad_solicitada_check CHECK ((cantidad_solicitada > (0)::numeric)),
    CONSTRAINT despacho_detalles_check CHECK ((cantidad_entregada <= cantidad_aprobada)),
    CONSTRAINT despacho_detalles_estado_conformidad_check CHECK (((estado_conformidad)::text = ANY ((ARRAY['CONFORME'::character varying, 'OBSERVADO'::character varying, 'RECHAZADO'::character varying])::text[])))
);


ALTER TABLE public.despacho_detalles OWNER TO postgres;

--
-- Name: despacho_detalles_id_despacho_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.despacho_detalles ALTER COLUMN id_despacho_detalle ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.despacho_detalles_id_despacho_detalle_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: despachos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.despachos (
    id_despacho integer NOT NULL,
    numero_despacho character varying(40) NOT NULL,
    id_pedido integer NOT NULL,
    id_area_solicitante integer NOT NULL,
    id_usuario_solicitante integer NOT NULL,
    id_almacen_salida integer NOT NULL,
    id_responsable_almacen integer,
    persona_recibe character varying(150) NOT NULL,
    fecha_programada_entrega date,
    fecha_real_entrega timestamp with time zone DEFAULT now() NOT NULL,
    tipo_despacho character varying(30) NOT NULL,
    estado_despacho character varying(40) NOT NULL,
    confirmacion_recepcion boolean DEFAULT false NOT NULL,
    evidencia_entrega character varying(255),
    observaciones text,
    usuario_registra integer,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT despachos_estado_despacho_check CHECK (((estado_despacho)::text = ANY ((ARRAY['PENDIENTE_ENTREGA'::character varying, 'ENTREGADO_PARCIAL'::character varying, 'ENTREGADO_COMPLETO'::character varying, 'CANCELADO'::character varying, 'OBSERVADO'::character varying])::text[]))),
    CONSTRAINT despachos_tipo_despacho_check CHECK (((tipo_despacho)::text = ANY ((ARRAY['NORMAL'::character varying, 'URGENTE'::character varying, 'PARCIAL'::character varying, 'DEVOLUCION'::character varying, 'REPOSICION'::character varying])::text[])))
);


ALTER TABLE public.despachos OWNER TO postgres;

--
-- Name: despachos_id_despacho_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.despachos ALTER COLUMN id_despacho ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.despachos_id_despacho_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: insumos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.insumos (
    id_insumo integer NOT NULL,
    id_categoria integer NOT NULL,
    id_tipo_insumo integer NOT NULL,
    id_unidad_medida integer NOT NULL,
    id_unidad_medida_secundaria integer,
    codigo_interno character varying(40) NOT NULL,
    codigo_barra_qr character varying(80),
    nombre_insumo character varying(150) NOT NULL,
    descripcion text,
    marca character varying(100),
    modelo character varying(100),
    presentacion character varying(100),
    precio_referencial numeric(14,2) DEFAULT 0 NOT NULL,
    ubicacion_sugerida character varying(120),
    requiere_control_especial boolean DEFAULT false NOT NULL,
    es_peligroso_inflamable boolean DEFAULT false NOT NULL,
    fecha_vencimiento date,
    imagen_url character varying(255),
    ficha_tecnica_url character varying(255),
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    observaciones text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    creado_por integer,
    actualizado_por integer,
    stock_minimo numeric(14,2) DEFAULT 0 NOT NULL,
    CONSTRAINT ck_insumos_stock_minimo_no_negativo CHECK ((stock_minimo >= (0)::numeric)),
    CONSTRAINT insumos_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying, 'ELIMINADO'::character varying])::text[]))),
    CONSTRAINT insumos_precio_referencial_check CHECK ((precio_referencial >= (0)::numeric))
);


ALTER TABLE public.insumos OWNER TO postgres;

--
-- Name: insumos_id_insumo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.insumos ALTER COLUMN id_insumo ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.insumos_id_insumo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: inventarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventarios (
    id_inventario integer NOT NULL,
    id_insumo integer NOT NULL,
    id_almacen integer NOT NULL,
    stock_fisico numeric(14,2) DEFAULT 0 NOT NULL,
    stock_reservado numeric(14,2) DEFAULT 0 NOT NULL,
    stock_disponible numeric(14,2) GENERATED ALWAYS AS ((stock_fisico - stock_reservado)) STORED,
    costo_promedio numeric(14,2) DEFAULT 0 NOT NULL,
    valor_total_stock numeric(14,2) GENERATED ALWAYS AS ((stock_fisico * costo_promedio)) STORED,
    lote character varying(80),
    numero_serie character varying(80),
    fecha_vencimiento date,
    ubicacion_interna character varying(120),
    estado_stock character varying(30) DEFAULT 'DISPONIBLE'::character varying NOT NULL,
    fecha_ultima_actualizacion timestamp with time zone DEFAULT now() NOT NULL,
    creado_por integer,
    actualizado_por integer,
    CONSTRAINT inventarios_check CHECK ((stock_reservado <= stock_fisico)),
    CONSTRAINT inventarios_costo_promedio_check CHECK ((costo_promedio >= (0)::numeric)),
    CONSTRAINT inventarios_estado_stock_check CHECK (((estado_stock)::text = ANY ((ARRAY['DISPONIBLE'::character varying, 'RESERVADO'::character varying, 'AGOTADO'::character varying, 'OBSERVADO'::character varying])::text[]))),
    CONSTRAINT inventarios_stock_fisico_check CHECK ((stock_fisico >= (0)::numeric)),
    CONSTRAINT inventarios_stock_reservado_check CHECK ((stock_reservado >= (0)::numeric))
);


ALTER TABLE public.inventarios OWNER TO postgres;

--
-- Name: inventarios_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.inventarios ALTER COLUMN id_inventario ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.inventarios_id_inventario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: movimientos_inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimientos_inventario (
    id_movimiento integer NOT NULL,
    numero_movimiento character varying(40) NOT NULL,
    fecha_movimiento timestamp with time zone DEFAULT now() NOT NULL,
    tipo_movimiento character varying(40) NOT NULL,
    id_insumo integer NOT NULL,
    id_almacen_origen integer,
    id_almacen_destino integer,
    cantidad numeric(14,2) NOT NULL,
    costo_unitario numeric(14,2) DEFAULT 0,
    motivo text NOT NULL,
    documento_respaldo character varying(255),
    usuario_responsable integer,
    observaciones text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    id_despacho integer,
    id_recepcion integer,
    codigo_referencia character varying(50),
    CONSTRAINT movimientos_inventario_cantidad_check CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT movimientos_inventario_costo_unitario_check CHECK ((costo_unitario >= (0)::numeric)),
    CONSTRAINT movimientos_inventario_tipo_movimiento_check CHECK (((tipo_movimiento)::text = ANY ((ARRAY['ENTRADA_COMPRA'::character varying, 'SALIDA_DESPACHO'::character varying, 'AJUSTE_POSITIVO'::character varying, 'AJUSTE_NEGATIVO'::character varying, 'DEVOLUCION'::character varying, 'TRANSFERENCIA_SALIDA'::character varying, 'TRANSFERENCIA_ENTRADA'::character varying])::text[])))
);


ALTER TABLE public.movimientos_inventario OWNER TO postgres;

--
-- Name: movimientos_inventario_id_movimiento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.movimientos_inventario ALTER COLUMN id_movimiento ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.movimientos_inventario_id_movimiento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notificaciones; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notificaciones (
    id_notificacion integer NOT NULL,
    tipo_notificacion character varying(50) NOT NULL,
    titulo character varying(150) NOT NULL,
    mensaje text NOT NULL,
    id_usuario_destinatario integer NOT NULL,
    modulo_relacionado character varying(80),
    id_registro_relacionado integer,
    prioridad character varying(20) DEFAULT 'MEDIA'::character varying NOT NULL,
    estado_notificacion character varying(20) DEFAULT 'NO_LEIDA'::character varying NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_lectura timestamp with time zone,
    usuario_genera integer,
    CONSTRAINT notificaciones_estado_notificacion_check CHECK (((estado_notificacion)::text = ANY ((ARRAY['NO_LEIDA'::character varying, 'LEIDA'::character varying, 'ARCHIVADA'::character varying])::text[]))),
    CONSTRAINT notificaciones_prioridad_check CHECK (((prioridad)::text = ANY ((ARRAY['BAJA'::character varying, 'MEDIA'::character varying, 'ALTA'::character varying, 'URGENTE'::character varying])::text[]))),
    CONSTRAINT notificaciones_tipo_notificacion_check CHECK (((tipo_notificacion)::text = ANY ((ARRAY['STOCK_BAJO'::character varying, 'INSUMO_SIN_STOCK'::character varying, 'PEDIDO_CREADO'::character varying, 'PEDIDO_APROBADO'::character varying, 'PEDIDO_RECHAZADO'::character varying, 'PEDIDO_OBSERVADO'::character varying, 'PEDIDO_EN_COMPRA'::character varying, 'COMPRA_REGISTRADA'::character varying, 'COMPRA_RECIBIDA_PARCIAL'::character varying, 'COMPRA_RECIBIDA_COMPLETA'::character varying, 'DESPACHO_REALIZADO'::character varying, 'COMPROBANTE_REGISTRADO'::character varying, 'COMPROBANTE_OBSERVADO'::character varying, 'USUARIO_CREADO'::character varying, 'AUDITORIA_IMPORTANTE'::character varying])::text[])))
);


ALTER TABLE public.notificaciones OWNER TO postgres;

--
-- Name: notificaciones_id_notificacion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.notificaciones ALTER COLUMN id_notificacion ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notificaciones_id_notificacion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: orden_compra_detalles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.orden_compra_detalles (
    id_orden_detalle integer NOT NULL,
    id_orden_compra integer NOT NULL,
    id_insumo integer NOT NULL,
    cantidad_solicitada numeric(14,2) NOT NULL,
    cantidad_comprada numeric(14,2) NOT NULL,
    precio_unitario numeric(14,2) NOT NULL,
    subtotal numeric(14,2) GENERATED ALWAYS AS ((cantidad_comprada * precio_unitario)) STORED,
    observacion text,
    CONSTRAINT orden_compra_detalles_cantidad_comprada_check CHECK ((cantidad_comprada > (0)::numeric)),
    CONSTRAINT orden_compra_detalles_cantidad_solicitada_check CHECK ((cantidad_solicitada > (0)::numeric)),
    CONSTRAINT orden_compra_detalles_precio_unitario_check CHECK ((precio_unitario >= (0)::numeric))
);


ALTER TABLE public.orden_compra_detalles OWNER TO postgres;

--
-- Name: orden_compra_detalles_id_orden_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.orden_compra_detalles ALTER COLUMN id_orden_detalle ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.orden_compra_detalles_id_orden_detalle_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ordenes_compra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ordenes_compra (
    id_orden_compra integer NOT NULL,
    numero_orden character varying(40) NOT NULL,
    codigo_correlativo character varying(40) NOT NULL,
    id_pedido integer,
    id_proveedor integer NOT NULL,
    fecha_emision date DEFAULT CURRENT_DATE NOT NULL,
    fecha_estimada_entrega date,
    condicion_pago character varying(120),
    forma_pago character varying(120),
    moneda character varying(10) DEFAULT 'BOB'::character varying NOT NULL,
    estado_pago character varying(30) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    descuento numeric(14,2) DEFAULT 0 NOT NULL,
    impuesto numeric(14,2) DEFAULT 0 NOT NULL,
    total_final numeric(14,2) GENERATED ALWAYS AS (((subtotal - descuento) + impuesto)) STORED,
    estado_compra character varying(40) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    observaciones text,
    usuario_genera integer,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    CONSTRAINT ordenes_compra_descuento_check CHECK ((descuento >= (0)::numeric)),
    CONSTRAINT ordenes_compra_estado_compra_check CHECK (((estado_compra)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'EN_PROCESO'::character varying, 'RECIBIDA_PARCIAL'::character varying, 'RECIBIDA_COMPLETA'::character varying, 'ANULADA'::character varying])::text[]))),
    CONSTRAINT ordenes_compra_estado_pago_check CHECK (((estado_pago)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'PAGADO_PARCIAL'::character varying, 'PAGADO_COMPLETO'::character varying, 'ANULADO'::character varying])::text[]))),
    CONSTRAINT ordenes_compra_impuesto_check CHECK ((impuesto >= (0)::numeric)),
    CONSTRAINT ordenes_compra_subtotal_check CHECK ((subtotal >= (0)::numeric))
);


ALTER TABLE public.ordenes_compra OWNER TO postgres;

--
-- Name: ordenes_compra_id_orden_compra_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.ordenes_compra ALTER COLUMN id_orden_compra ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.ordenes_compra_id_orden_compra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pedido_detalles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedido_detalles (
    id_pedido_detalle integer NOT NULL,
    id_pedido integer NOT NULL,
    id_insumo integer NOT NULL,
    cantidad_solicitada numeric(14,2) NOT NULL,
    cantidad_aprobada numeric(14,2) DEFAULT 0 NOT NULL,
    cantidad_despachada numeric(14,2) DEFAULT 0 NOT NULL,
    cantidad_pendiente numeric(14,2) GENERATED ALWAYS AS ((cantidad_aprobada - cantidad_despachada)) STORED,
    observacion text,
    CONSTRAINT pedido_detalles_cantidad_aprobada_check CHECK ((cantidad_aprobada >= (0)::numeric)),
    CONSTRAINT pedido_detalles_cantidad_despachada_check CHECK ((cantidad_despachada >= (0)::numeric)),
    CONSTRAINT pedido_detalles_cantidad_solicitada_check CHECK ((cantidad_solicitada > (0)::numeric)),
    CONSTRAINT pedido_detalles_check CHECK ((cantidad_aprobada <= cantidad_solicitada)),
    CONSTRAINT pedido_detalles_check1 CHECK ((cantidad_despachada <= cantidad_aprobada))
);


ALTER TABLE public.pedido_detalles OWNER TO postgres;

--
-- Name: pedido_detalles_id_pedido_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.pedido_detalles ALTER COLUMN id_pedido_detalle ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.pedido_detalles_id_pedido_detalle_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedidos (
    id_pedido integer NOT NULL,
    numero_pedido character varying(40) NOT NULL,
    id_usuario_solicitante integer NOT NULL,
    id_area_solicitante integer NOT NULL,
    fecha_pedido timestamp with time zone DEFAULT now() NOT NULL,
    fecha_requerida timestamp with time zone NOT NULL,
    tipo_pedido character varying(30) NOT NULL,
    prioridad character varying(20) NOT NULL,
    justificacion text NOT NULL,
    estado_pedido character varying(40) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    estado_aprobacion character varying(30) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    estado_atencion character varying(40) DEFAULT 'SIN_ATENDER'::character varying NOT NULL,
    id_proveedor_sugerido integer,
    archivo_adjunto character varying(255),
    centro_costo character varying(80),
    turno_guardia character varying(80),
    observaciones text,
    id_usuario_revisor integer,
    fecha_revision timestamp with time zone,
    motivo_rechazo text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    creado_por integer,
    actualizado_por integer,
    lugar_uso character varying(150),
    CONSTRAINT pedidos_estado_aprobacion_check CHECK (((estado_aprobacion)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'APROBADO'::character varying, 'RECHAZADO'::character varying, 'OBSERVADO'::character varying])::text[]))),
    CONSTRAINT pedidos_estado_atencion_check CHECK (((estado_atencion)::text = ANY ((ARRAY['SIN_ATENDER'::character varying, 'EN_PROCESO'::character varying, 'ATENDIDO_PARCIAL'::character varying, 'ATENDIDO_TOTAL'::character varying])::text[]))),
    CONSTRAINT pedidos_estado_pedido_check CHECK (((estado_pedido)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'APROBADO'::character varying, 'RECHAZADO'::character varying, 'OBSERVADO'::character varying, 'EN_COMPRA'::character varying, 'EN_DESPACHO'::character varying, 'ENTREGADO_PARCIAL'::character varying, 'ENTREGADO_COMPLETO'::character varying, 'CANCELADO'::character varying])::text[]))),
    CONSTRAINT pedidos_prioridad_check CHECK (((prioridad)::text = ANY ((ARRAY['BAJA'::character varying, 'MEDIA'::character varying, 'ALTA'::character varying, 'URGENTE'::character varying])::text[]))),
    CONSTRAINT pedidos_tipo_pedido_check CHECK (((tipo_pedido)::text = ANY ((ARRAY['NORMAL'::character varying, 'URGENTE'::character varying, 'REPOSICION'::character varying, 'EMERGENCIA'::character varying, 'MANTENIMIENTO'::character varying, 'OPERACION'::character varying])::text[])))
);


ALTER TABLE public.pedidos OWNER TO postgres;

--
-- Name: pedidos_id_pedido_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.pedidos ALTER COLUMN id_pedido ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.pedidos_id_pedido_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: permisos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permisos (
    id_permiso integer NOT NULL,
    codigo_permiso character varying(80) NOT NULL,
    modulo character varying(80) NOT NULL,
    descripcion text NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.permisos OWNER TO postgres;

--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.permisos ALTER COLUMN id_permiso ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.permisos_id_permiso_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: politicas_stock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.politicas_stock (
    id_politica_stock integer NOT NULL,
    id_insumo integer NOT NULL,
    id_almacen integer NOT NULL,
    stock_minimo numeric(14,2) DEFAULT 0 NOT NULL,
    stock_maximo numeric(14,2) DEFAULT 0 NOT NULL,
    stock_seguridad numeric(14,2) DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    creado_por integer,
    CONSTRAINT politicas_stock_check CHECK (((stock_maximo = (0)::numeric) OR (stock_maximo >= stock_minimo))),
    CONSTRAINT politicas_stock_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying])::text[]))),
    CONSTRAINT politicas_stock_stock_maximo_check CHECK ((stock_maximo >= (0)::numeric)),
    CONSTRAINT politicas_stock_stock_minimo_check CHECK ((stock_minimo >= (0)::numeric)),
    CONSTRAINT politicas_stock_stock_seguridad_check CHECK ((stock_seguridad >= (0)::numeric))
);


ALTER TABLE public.politicas_stock OWNER TO postgres;

--
-- Name: politicas_stock_id_politica_stock_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.politicas_stock ALTER COLUMN id_politica_stock ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.politicas_stock_id_politica_stock_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: proveedor_insumo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proveedor_insumo (
    id_proveedor integer NOT NULL,
    id_insumo integer NOT NULL,
    precio_referencial numeric(14,2),
    tiempo_entrega_dias integer,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    CONSTRAINT proveedor_insumo_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying])::text[]))),
    CONSTRAINT proveedor_insumo_precio_referencial_check CHECK (((precio_referencial IS NULL) OR (precio_referencial >= (0)::numeric))),
    CONSTRAINT proveedor_insumo_tiempo_entrega_dias_check CHECK (((tiempo_entrega_dias IS NULL) OR (tiempo_entrega_dias >= 0)))
);


ALTER TABLE public.proveedor_insumo OWNER TO postgres;

--
-- Name: proveedores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proveedores (
    id_proveedor integer NOT NULL,
    codigo_proveedor character varying(30) NOT NULL,
    razon_social character varying(150) NOT NULL,
    nombre_comercial character varying(150),
    nit character varying(30) NOT NULL,
    rubro character varying(120) NOT NULL,
    tipo_insumos_provee text,
    persona_contacto character varying(120),
    cargo_contacto character varying(100),
    telefono character varying(30),
    celular_whatsapp character varying(30),
    correo character varying(150),
    direccion text,
    ciudad character varying(80),
    condiciones_pago character varying(120),
    forma_pago character varying(120),
    tiempo_estimado_entrega character varying(80),
    calificacion numeric(3,2),
    documentacion_vigente boolean DEFAULT true,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    observaciones text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    creado_por integer,
    actualizado_por integer,
    CONSTRAINT proveedores_calificacion_check CHECK (((calificacion IS NULL) OR ((calificacion >= (0)::numeric) AND (calificacion <= (5)::numeric)))),
    CONSTRAINT proveedores_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying, 'ELIMINADO'::character varying])::text[])))
);


ALTER TABLE public.proveedores OWNER TO postgres;

--
-- Name: proveedores_id_proveedor_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.proveedores ALTER COLUMN id_proveedor ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.proveedores_id_proveedor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recepcion_detalles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recepcion_detalles (
    id_recepcion_detalle integer NOT NULL,
    id_recepcion integer NOT NULL,
    id_orden_detalle integer NOT NULL,
    id_insumo integer NOT NULL,
    cantidad_comprada numeric(14,2) NOT NULL,
    cantidad_recibida numeric(14,2) NOT NULL,
    cantidad_aceptada numeric(14,2) NOT NULL,
    cantidad_rechazada numeric(14,2) DEFAULT 0 NOT NULL,
    cantidad_faltante numeric(14,2) DEFAULT 0 NOT NULL,
    motivo_rechazo text,
    estado_conformidad character varying(30) NOT NULL,
    observaciones text,
    CONSTRAINT recepcion_detalles_cantidad_aceptada_check CHECK ((cantidad_aceptada >= (0)::numeric)),
    CONSTRAINT recepcion_detalles_cantidad_comprada_check CHECK ((cantidad_comprada > (0)::numeric)),
    CONSTRAINT recepcion_detalles_cantidad_faltante_check CHECK ((cantidad_faltante >= (0)::numeric)),
    CONSTRAINT recepcion_detalles_cantidad_rechazada_check CHECK ((cantidad_rechazada >= (0)::numeric)),
    CONSTRAINT recepcion_detalles_cantidad_recibida_check CHECK ((cantidad_recibida >= (0)::numeric)),
    CONSTRAINT recepcion_detalles_check CHECK (((cantidad_aceptada + cantidad_rechazada) <= cantidad_recibida)),
    CONSTRAINT recepcion_detalles_estado_conformidad_check CHECK (((estado_conformidad)::text = ANY ((ARRAY['CONFORME'::character varying, 'OBSERVADO'::character varying, 'RECHAZADO'::character varying])::text[])))
);


ALTER TABLE public.recepcion_detalles OWNER TO postgres;

--
-- Name: recepcion_detalles_id_recepcion_detalle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.recepcion_detalles ALTER COLUMN id_recepcion_detalle ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.recepcion_detalles_id_recepcion_detalle_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: recepciones_compra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recepciones_compra (
    id_recepcion integer NOT NULL,
    numero_recepcion character varying(40) NOT NULL,
    id_orden_compra integer NOT NULL,
    id_proveedor integer NOT NULL,
    id_almacen_destino integer NOT NULL,
    fecha_estimada_recepcion date,
    fecha_real_recepcion date DEFAULT CURRENT_DATE NOT NULL,
    id_responsable_recepcion integer,
    estado_recepcion character varying(40) NOT NULL,
    documento_respaldo character varying(255),
    observaciones text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT recepciones_compra_estado_recepcion_check CHECK (((estado_recepcion)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'RECIBIDA_PARCIAL'::character varying, 'RECIBIDA_COMPLETA'::character varying, 'OBSERVADA'::character varying, 'RECHAZADA'::character varying])::text[])))
);


ALTER TABLE public.recepciones_compra OWNER TO postgres;

--
-- Name: recepciones_compra_id_recepcion_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.recepciones_compra ALTER COLUMN id_recepcion ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.recepciones_compra_id_recepcion_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reservas_stock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservas_stock (
    id_reserva_stock integer NOT NULL,
    id_inventario integer NOT NULL,
    id_insumo integer NOT NULL,
    id_almacen integer NOT NULL,
    id_pedido integer NOT NULL,
    id_pedido_detalle integer NOT NULL,
    cantidad_reservada numeric(14,2) DEFAULT 0 NOT NULL,
    estado character varying(20) DEFAULT 'ACTIVA'::character varying NOT NULL,
    fecha_reserva timestamp with time zone DEFAULT now() NOT NULL,
    fecha_liberacion timestamp with time zone,
    CONSTRAINT reservas_stock_cantidad_reservada_check CHECK ((cantidad_reservada >= (0)::numeric)),
    CONSTRAINT reservas_stock_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVA'::character varying, 'LIBERADA'::character varying])::text[])))
);


ALTER TABLE public.reservas_stock OWNER TO postgres;

--
-- Name: reservas_stock_id_reserva_stock_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.reservas_stock ALTER COLUMN id_reserva_stock ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.reservas_stock_id_reserva_stock_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles (
    id_rol integer NOT NULL,
    nombre_rol character varying(80) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    CONSTRAINT roles_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying])::text[])))
);


ALTER TABLE public.roles OWNER TO postgres;

--
-- Name: roles_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.roles ALTER COLUMN id_rol ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.roles_id_rol_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: roles_permisos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roles_permisos (
    id_rol integer NOT NULL,
    id_permiso integer NOT NULL
);


ALTER TABLE public.roles_permisos OWNER TO postgres;

--
-- Name: tipos_insumo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipos_insumo (
    id_tipo_insumo integer NOT NULL,
    nombre_tipo character varying(100) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    creado_por integer,
    CONSTRAINT tipos_insumo_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying])::text[])))
);


ALTER TABLE public.tipos_insumo OWNER TO postgres;

--
-- Name: tipos_insumo_id_tipo_insumo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tipos_insumo ALTER COLUMN id_tipo_insumo ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.tipos_insumo_id_tipo_insumo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: unidades_medida; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.unidades_medida (
    id_unidad_medida integer NOT NULL,
    nombre_unidad character varying(80) NOT NULL,
    abreviatura character varying(20) NOT NULL,
    descripcion text,
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT unidades_medida_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying])::text[])))
);


ALTER TABLE public.unidades_medida OWNER TO postgres;

--
-- Name: unidades_medida_id_unidad_medida_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.unidades_medida ALTER COLUMN id_unidad_medida ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.unidades_medida_id_unidad_medida_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios (
    id_usuario integer NOT NULL,
    id_area integer NOT NULL,
    id_rol integer NOT NULL,
    nombre_completo character varying(150) NOT NULL,
    nombre_usuario character varying(80) NOT NULL,
    correo character varying(150) NOT NULL,
    password_hash character varying(255) NOT NULL,
    telefono character varying(30),
    cargo character varying(100),
    estado character varying(20) DEFAULT 'ACTIVO'::character varying NOT NULL,
    ultimo_inicio_sesion timestamp with time zone,
    intentos_fallidos integer DEFAULT 0 NOT NULL,
    cambio_obligatorio boolean DEFAULT false NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    creado_por integer,
    actualizado_por integer,
    cedula_identidad character varying(30),
    complemento_ci character varying(10),
    expedido_ci character varying(20),
    CONSTRAINT usuarios_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying, 'ELIMINADO'::character varying])::text[]))),
    CONSTRAINT usuarios_intentos_fallidos_check CHECK ((intentos_fallidos >= 0))
);


ALTER TABLE public.usuarios OWNER TO postgres;

--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.usuarios ALTER COLUMN id_usuario ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.usuarios_id_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_compras_por_proveedor; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_compras_por_proveedor AS
 SELECT p.codigo_proveedor,
    p.razon_social,
    count(oc.id_orden_compra) AS total_compras,
    COALESCE(sum(oc.total_final), (0)::numeric) AS monto_total_comprado
   FROM (public.proveedores p
     LEFT JOIN public.ordenes_compra oc ON ((oc.id_proveedor = p.id_proveedor)))
  GROUP BY p.codigo_proveedor, p.razon_social;


ALTER VIEW public.v_compras_por_proveedor OWNER TO postgres;

--
-- Name: v_stock_actual; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_stock_actual AS
 SELECT i.id_inventario,
    ins.codigo_interno,
    ins.nombre_insumo,
    c.nombre_categoria,
    ti.nombre_tipo,
    um.abreviatura AS unidad_medida,
    a.codigo_almacen,
    a.nombre_almacen,
    a.tipo_almacen,
    i.stock_fisico,
    i.stock_reservado,
    i.stock_disponible,
    COALESCE(ps.stock_minimo, (0)::numeric) AS stock_minimo,
    COALESCE(ps.stock_maximo, (0)::numeric) AS stock_maximo,
    COALESCE(ps.stock_seguridad, (0)::numeric) AS stock_seguridad,
    i.costo_promedio,
    i.valor_total_stock,
    i.estado_stock,
    i.fecha_ultima_actualizacion
   FROM ((((((public.inventarios i
     JOIN public.insumos ins ON ((ins.id_insumo = i.id_insumo)))
     JOIN public.categorias_insumo c ON ((c.id_categoria = ins.id_categoria)))
     JOIN public.tipos_insumo ti ON ((ti.id_tipo_insumo = ins.id_tipo_insumo)))
     JOIN public.unidades_medida um ON ((um.id_unidad_medida = ins.id_unidad_medida)))
     JOIN public.almacenes a ON ((a.id_almacen = i.id_almacen)))
     LEFT JOIN public.politicas_stock ps ON (((ps.id_insumo = i.id_insumo) AND (ps.id_almacen = i.id_almacen))));


ALTER VIEW public.v_stock_actual OWNER TO postgres;

--
-- Name: v_stock_bajo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_stock_bajo AS
 SELECT id_inventario,
    codigo_interno,
    nombre_insumo,
    nombre_categoria,
    nombre_tipo,
    unidad_medida,
    codigo_almacen,
    nombre_almacen,
    tipo_almacen,
    stock_fisico,
    stock_reservado,
    stock_disponible,
    stock_minimo,
    stock_maximo,
    stock_seguridad,
    costo_promedio,
    valor_total_stock,
    estado_stock,
    fecha_ultima_actualizacion
   FROM public.v_stock_actual
  WHERE (stock_disponible <= stock_minimo);


ALTER VIEW public.v_stock_bajo OWNER TO postgres;

--
-- Name: v_dashboard_resumen; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_dashboard_resumen AS
 SELECT ( SELECT count(*) AS count
           FROM public.insumos
          WHERE ((insumos.estado)::text = 'ACTIVO'::text)) AS total_insumos_activos,
    ( SELECT count(*) AS count
           FROM public.proveedores
          WHERE ((proveedores.estado)::text = 'ACTIVO'::text)) AS total_proveedores_activos,
    ( SELECT count(*) AS count
           FROM public.almacenes
          WHERE ((almacenes.estado)::text = 'ACTIVO'::text)) AS total_almacenes_activos,
    ( SELECT count(*) AS count
           FROM public.usuarios
          WHERE ((usuarios.estado)::text = 'ACTIVO'::text)) AS total_usuarios_activos,
    ( SELECT count(*) AS count
           FROM public.pedidos
          WHERE ((pedidos.estado_pedido)::text = 'PENDIENTE'::text)) AS pedidos_pendientes,
    ( SELECT count(*) AS count
           FROM public.pedidos
          WHERE ((pedidos.estado_pedido)::text = 'APROBADO'::text)) AS pedidos_aprobados,
    ( SELECT count(*) AS count
           FROM public.ordenes_compra
          WHERE ((ordenes_compra.estado_compra)::text = ANY (ARRAY[('PENDIENTE'::character varying)::text, ('EN_PROCESO'::character varying)::text]))) AS compras_en_proceso,
    ( SELECT count(*) AS count
           FROM public.ordenes_compra
          WHERE ((ordenes_compra.estado_compra)::text = 'RECIBIDA_COMPLETA'::text)) AS compras_recibidas,
    ( SELECT count(*) AS count
           FROM public.v_stock_bajo) AS insumos_con_stock_bajo,
    ( SELECT COALESCE(sum(inventarios.valor_total_stock), (0)::numeric) AS "coalesce"
           FROM public.inventarios) AS valor_total_inventario;


ALTER VIEW public.v_dashboard_resumen OWNER TO postgres;

--
-- Name: v_kardex; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_kardex AS
 SELECT mi.fecha_movimiento,
    mi.numero_movimiento,
    ins.codigo_interno,
    ins.nombre_insumo,
    mi.tipo_movimiento,
        CASE
            WHEN ((mi.tipo_movimiento)::text = ANY (ARRAY[('ENTRADA_COMPRA'::character varying)::text, ('AJUSTE_POSITIVO'::character varying)::text, ('DEVOLUCION'::character varying)::text, ('TRANSFERENCIA_ENTRADA'::character varying)::text])) THEN mi.cantidad
            ELSE (0)::numeric
        END AS entrada,
        CASE
            WHEN ((mi.tipo_movimiento)::text = ANY (ARRAY[('SALIDA_DESPACHO'::character varying)::text, ('AJUSTE_NEGATIVO'::character varying)::text, ('TRANSFERENCIA_SALIDA'::character varying)::text])) THEN mi.cantidad
            ELSE (0)::numeric
        END AS salida,
    mi.costo_unitario,
    mi.motivo,
    COALESCE(ao.nombre_almacen, '-'::character varying) AS almacen_origen,
    COALESCE(ad.nombre_almacen, '-'::character varying) AS almacen_destino,
    u.nombre_completo AS usuario_responsable,
    mi.documento_respaldo,
    mi.observaciones
   FROM ((((public.movimientos_inventario mi
     JOIN public.insumos ins ON ((ins.id_insumo = mi.id_insumo)))
     LEFT JOIN public.almacenes ao ON ((ao.id_almacen = mi.id_almacen_origen)))
     LEFT JOIN public.almacenes ad ON ((ad.id_almacen = mi.id_almacen_destino)))
     LEFT JOIN public.usuarios u ON ((u.id_usuario = mi.usuario_responsable)));


ALTER VIEW public.v_kardex OWNER TO postgres;

--
-- Name: v_pedidos_por_estado; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_pedidos_por_estado AS
 SELECT estado_pedido,
    count(*) AS total_pedidos
   FROM public.pedidos
  GROUP BY estado_pedido;


ALTER VIEW public.v_pedidos_por_estado OWNER TO postgres;

--
-- Data for Name: almacenes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.almacenes (id_almacen, codigo_almacen, nombre_almacen, tipo_almacen, ubicacion, id_responsable_principal, id_responsable_suplente, telefono_contacto, horario_atencion, descripcion, capacidad_maxima, capacidad_minima_recomendada, tipo_almacenamiento, observaciones_seguridad, estado, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
3	ALM-COM-001	Almacén de combustible	COMBUSTIBLE	Patio de abastecimiento	2	\N	70000002	Lunes a sábado 07:00 - 17:00	Almacén para combustible de operación.	5000.00	500.00	Tanques y contenedores certificados	Mantener señalización y control de inflamables.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-06 17:42:46.66+00	1	\N
5	alm-2245	alamecen superfice 1	SUPERFICIE	sertor -30	15	\N	74747474	08:00-13:78	ingreso de insumos a -30 minera23	\N	\N	\N	\N	ELIMINADO	2026-07-08 00:30:06.574821+00	2026-07-08 00:38:45.210413+00	\N	\N
4	ALM-23	ALMACEN SUPERFICIE 2	TEMPORAL	INTERIOR MINA	2	\N	74477014	08:00-10:00	ingreso de insumos nivel 70	\N	\N	\N	\N	ACTIVO	2026-07-07 19:25:43.935124+00	2026-07-15 18:23:36.591+00	\N	\N
1	ALM-SUP-1	Almacén de superficie	SUPERFICIE	Zona administrativa de superficie	2	\N	70000002	Lunes a sábado 08:00 - 18:00	Almacén principal de insumos generales.	10000.00	1000.00	Almacenamiento general	Ingreso restringido a personal autorizado.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-15 18:37:44.277+00	1	\N
2	ALM-POL-01	Polvorín principal	POLVORIN	Zona segura y aislada de operación	2	\N	70000002	Bajo autorización	Almacén para material controlado.	500.00	50.00	Almacenamiento especial controlado	Requiere control, autorización y trazabilidad estricta.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-15 20:00:48.355+00	1	\N
\.


--
-- Data for Name: aprobaciones_pedido; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.aprobaciones_pedido (id_aprobacion, id_pedido, id_usuario_aprobador, nivel_aprobacion, fecha_aprobacion, estado_aprobacion, observaciones, motivo_rechazo, fecha_creacion) FROM stdin;
1	1	3	1	2026-07-04 13:59:53.677794+00	APROBADO	Aprobado por necesidad operativa.	\N	2026-07-04 13:59:53.677794+00
2	2	3	1	2026-07-04 13:59:53.677794+00	APROBADO	Aprobado por trabajo programado de perforación.	\N	2026-07-04 13:59:53.677794+00
3	3	3	1	2026-07-04 13:59:53.677794+00	APROBADO	Aprobado para mantenimiento preventivo.	\N	2026-07-04 13:59:53.677794+00
\.


--
-- Data for Name: areas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.areas (id_area, nombre_area, descripcion, estado, fecha_creacion, fecha_actualizacion) FROM stdin;
3	Seguridad Industrial	Área responsable de la seguridad industrial y dotación de EPP.	ACTIVO	2026-07-04 13:59:53.677794+00	\N
7	Transporte	Área de apoyo logístico y transporte.	ACTIVO	2026-07-04 13:59:53.677794+00	\N
8	Perforación	Área encargada de trabajos de perforación.	ACTIVO	2026-07-04 13:59:53.677794+00	\N
9	Operaciones	Área de coordinación operativa.	ACTIVO	2026-07-04 13:59:53.677794+00	\N
10	Gerencia	Área de dirección y toma de decisiones.	ACTIVO	2026-07-04 13:59:53.677794+00	\N
6	Administración	Administracion general del sistema.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-06 20:33:11.428352+00
5	Almacén	Gestion de almacenes e inventario.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-06 20:33:11.428352+00
1	Mina	Operacion mina.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-06 20:33:11.428352+00
4	Compras	Gestion de compras y proveedores.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-06 20:33:11.428352+00
2	Mantenimiento	Solicitudes de mantenimiento.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-06 20:33:11.428352+00
16	Auditoría	Revision y control interno.	ACTIVO	2026-07-06 20:33:11.428352+00	\N
\.


--
-- Data for Name: auditorias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.auditorias (id_auditoria, id_usuario, accion_realizada, tipo_accion, modulo_afectado, tabla_afectada, id_registro_afectado, registro_anterior, registro_nuevo, fecha_hora, direccion_ip, navegador_dispositivo, motivo_cambio, observaciones) FROM stdin;
1	1	Creación de usuario administrador	CREAR	Usuarios	usuarios	1	\N	{"estado": "ACTIVO", "usuario": "jperez"}	2026-07-04 13:59:53.677794+00	127.0.0.1	DBeaver / PostgreSQL	Configuración inicial	Registro de auditoría inicial.
2	4	Registro de orden de compra OC-2026-0002	REGISTRAR_COMPRA	Compras	ordenes_compra	2	\N	{"estado": "RECIBIDA_COMPLETA", "numero_orden": "OC-2026-0002"}	2026-07-04 13:59:53.677794+00	127.0.0.1	DBeaver / PostgreSQL	Compra para pedido aprobado	Orden de compra registrada.
3	2	Registro de despacho DES-2026-0003	REALIZAR_DESPACHO	Inventario y Despachos	despachos	3	\N	{"estado": "ENTREGADO_COMPLETO", "numero_despacho": "DES-2026-0003"}	2026-07-04 13:59:53.677794+00	127.0.0.1	DBeaver / PostgreSQL	Entrega de insumo solicitado	Despacho registrado correctamente.
14	1	Se desactivó el usuario pmamani.	DESACTIVAR	Usuarios	usuarios	6	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-06 21:38:49.152434+00	\N	\N	\N	\N
16	1	Se desactivó el usuario pmamani.	DESACTIVAR	Usuarios	usuarios	6	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-06 21:38:54.700363+00	\N	\N	\N	\N
18	1	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-06 21:41:27.753612+00	\N	\N	\N	\N
25	2	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-06 21:58:07.803889+00	\N	\N	\N	\N
28	1	Se desactivó el usuario pmamani.	DESACTIVAR	Usuarios	usuarios	6	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-06 22:00:00.33755+00	\N	\N	\N	\N
32	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 05:41:05.271415+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
33	1	Se activó el usuario pmamani.	ACTIVAR	Usuarios	usuarios	6	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 05:41:16.394894+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
34	1	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 05:44:23.934357+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
35	1	Se activó el almacén ALM-SUP-001.	ACTIVAR	Almacenes	almacenes	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 05:44:27.041514+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
36	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 05:46:09.645352+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
37	1	Se desactivó el insumo SEG-CAS-001.	DESACTIVAR	Insumos	insumos	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 05:47:08.357833+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
38	1	Se activó el insumo SEG-CAS-001.	ACTIVAR	Insumos	insumos	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 05:47:11.448412+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
39	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 05:54:48.045314+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
40	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-07 05:55:30.785776+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
41	2	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 05:55:43.78875+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
42	2	Se activó el almacén ALM-SUP-001.	ACTIVAR	Almacenes	almacenes	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 05:55:46.287672+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
43	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 05:55:53.439284+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
44	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 19:14:38.402919+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
45	\N	Login fallido de feyckon	INICIAR_SESION	Autenticación	usuarios	\N	\N	{"motivo": "Usuario no encontrado", "resultado": "FALLIDO", "nombreUsuario": "feyckon"}	2026-07-07 19:18:42.786791+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario no encontrado	Intento de inicio de sesiÃ³n no autorizado.
46	\N	Login fallido de feyckon	INICIAR_SESION	Autenticación	usuarios	\N	\N	{"motivo": "Usuario no encontrado", "resultado": "FALLIDO", "nombreUsuario": "feyckon"}	2026-07-07 19:18:47.774305+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario no encontrado	Intento de inicio de sesiÃ³n no autorizado.
47	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 19:18:55.751609+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
48	13	Se desactivó el usuario federico.	DESACTIVAR	Usuarios	usuarios	13	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 19:21:45.710917+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
49	13	Se activó el usuario federico.	ACTIVAR	Usuarios	usuarios	13	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 19:21:50.847647+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
50	13	Se desactivó el usuario jperez.	DESACTIVAR	Usuarios	usuarios	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 19:22:00.772372+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
51	1	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-07-07 19:22:09.708075+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
52	1	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-07-07 19:22:11.579069+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
53	1	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-07-07 19:22:12.160468+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
54	1	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-07-07 19:22:13.985184+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
55	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 19:22:28.11885+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
56	13	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 19:23:52.339244+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
57	13	Se activó el almacén ALM-SUP-001.	ACTIVAR	Almacenes	almacenes	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 19:23:54.368976+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
58	13	Se desactivó el proveedor PROV-22.	DESACTIVAR	Proveedores	proveedores	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 19:32:13.451878+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
59	13	Se activó el proveedor PROV-22.	ACTIVAR	Proveedores	proveedores	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 19:32:20.806614+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
60	13	Se desactivó el insumo INS-22.	DESACTIVAR	Insumos	insumos	8	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 19:34:06.351417+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
61	13	Se activó el insumo INS-22.	ACTIVAR	Insumos	insumos	8	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 19:34:08.578502+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
62	13	Se creo el pedido PED-20260707-998843.	CREAR	Pedidos	pedidos	4	\N	{"detalles": 1, "prioridad": "MEDIA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260707-998843", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-07 19:36:38.969508+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	material de perforacion	se requiere una broca punta diamante, para un barreno de 1.20 metros
63	1	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-07-07 20:32:13.114601+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
64	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 20:32:25.663523+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
65	13	Se creo el pedido PED-20260707-624414.	CREAR	Pedidos	pedidos	5	\N	{"detalles": 1, "prioridad": "BAJA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260707-624414", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-07 20:37:04.52173+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	federico	weretbrnthbg
66	13	Se rechazo el pedido PED-20260707-624414.	RECHAZAR	Pedidos	pedidos	5	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "RECHAZADO", "usuarioRevisa": 13, "estadoAprobacion": "RECHAZADO"}	2026-07-07 20:37:25.137824+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	nose
67	13	Se desactivó el insumo INS-22.	DESACTIVAR	Insumos	insumos	8	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 20:38:06.487058+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
68	13	Se desactivó el proveedor PROV-22.	DESACTIVAR	Proveedores	proveedores	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 20:38:32.278863+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
69	13	Se activó el proveedor PROV-22.	ACTIVAR	Proveedores	proveedores	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 20:38:34.312049+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
70	13	Se activó el usuario jperez.	ACTIVAR	Usuarios	usuarios	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 20:39:34.229133+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
71	13	Se activó el insumo INS-22.	ACTIVAR	Insumos	insumos	8	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 20:41:20.282125+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
72	13	Se desactivó el usuario pmamani.	DESACTIVAR	Usuarios	usuarios	6	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 20:44:57.713462+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
73	4	Login correcto de avargas	INICIAR_SESION	Autenticación	usuarios	4	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "avargas"}	2026-07-07 20:45:14.179256+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
74	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 20:46:08.108823+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
75	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 20:54:31.776368+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
76	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 21:00:38.900471+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
77	\N	Login fallido de imamani	INICIAR_SESION	Autenticación	usuarios	\N	\N	{"motivo": "Usuario no encontrado", "resultado": "FALLIDO", "nombreUsuario": "imamani"}	2026-07-07 21:00:54.628241+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario no encontrado	Intento de inicio de sesiÃ³n no autorizado.
78	\N	Login fallido de imamani	INICIAR_SESION	Autenticación	usuarios	\N	\N	{"motivo": "Usuario no encontrado", "resultado": "FALLIDO", "nombreUsuario": "imamani"}	2026-07-07 21:00:57.797462+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario no encontrado	Intento de inicio de sesiÃ³n no autorizado.
79	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 21:01:03.202809+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
80	5	Login correcto de lmamani	INICIAR_SESION	Autenticación	usuarios	5	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "lmamani"}	2026-07-07 21:01:15.094092+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
81	1	Login correcto de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "jperez"}	2026-07-07 21:03:30.176215+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
82	4	Login correcto de avargas	INICIAR_SESION	Autenticación	usuarios	4	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "avargas"}	2026-07-07 21:04:04.810952+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
83	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 21:30:40.576395+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
84	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 21:31:40.620218+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
85	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 21:35:48.615995+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
86	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 21:36:56.282131+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
87	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 21:55:36.182114+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
88	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 22:02:02.845575+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
89	13	Se elimino logicamente el usuario pmamani.	ELIMINAR	Usuarios	usuarios	6	{"estado": "INACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": false}	2026-07-07 22:02:12.323829+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
90	13	Se desactivó el usuario jperez.	DESACTIVAR	Usuarios	usuarios	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 22:03:03.288799+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
91	13	Se elimino logicamente el usuario jperez.	ELIMINAR	Usuarios	usuarios	1	{"estado": "INACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": true}	2026-07-07 22:03:18.029416+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
92	13	Se desactivó el usuario maria .	DESACTIVAR	Usuarios	usuarios	14	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 22:05:07.645411+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
93	13	Se activó el usuario maria .	ACTIVAR	Usuarios	usuarios	14	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 22:05:09.694054+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
94	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 22:10:09.915617+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
95	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 22:15:11.093828+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
96	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 22:20:52.630031+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
97	13	Se desactivó el usuario maria .	DESACTIVAR	Usuarios	usuarios	14	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 22:21:07.799832+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
98	13	Se activó el usuario maria .	ACTIVAR	Usuarios	usuarios	14	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 22:21:16.385332+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
99	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 22:27:57.627489+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
100	13	Se desactivó el usuario mcondori.	DESACTIVAR	Usuarios	usuarios	2	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 22:29:21.392079+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
101	13	Se activó el usuario mcondori.	ACTIVAR	Usuarios	usuarios	2	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 22:29:23.606836+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
102	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 22:34:49.024052+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
103	13	Se desactivó el usuario maria .	DESACTIVAR	Usuarios	usuarios	14	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 22:37:00.95048+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
104	13	Se activó el usuario maria .	ACTIVAR	Usuarios	usuarios	14	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 22:37:02.996089+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
105	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 22:43:20.579234+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
106	13	Se desactivó el proveedor PROV-22.	DESACTIVAR	Proveedores	proveedores	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 22:45:03.547368+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
107	13	Se activó el proveedor PROV-22.	ACTIVAR	Proveedores	proveedores	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 22:45:05.501291+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
108	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 22:59:00.089981+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
109	13	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 22:59:26.732286+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
110	13	Se activó el almacén ALM-SUP-001.	ACTIVAR	Almacenes	almacenes	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 22:59:28.63307+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
111	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:05:36.479534+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
112	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:09:59.901803+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
113	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:13:27.386317+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
114	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:20:52.378655+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
115	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:22:40.922588+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
116	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:23:49.393788+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
117	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:27:23.814702+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
118	13	Se elimino logicamente el usuario maria .	ELIMINAR	Usuarios	usuarios	14	{"estado": "ACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": false}	2026-07-07 23:28:02.610069+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
119	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:34:43.116245+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
120	13	Se desactivó el proveedor PROV-22.	DESACTIVAR	Proveedores	proveedores	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 23:35:36.543495+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
121	13	Se activó el proveedor PROV-22.	ACTIVAR	Proveedores	proveedores	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 23:35:38.707333+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
122	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:39:15.670946+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
123	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:42:22.233002+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
124	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:43:47.047031+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
125	13	Se desactivó el usuario maria.	DESACTIVAR	Usuarios	usuarios	15	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-07 23:49:13.71075+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
126	13	Se activó el usuario maria.	ACTIVAR	Usuarios	usuarios	15	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-07 23:49:15.444569+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
127	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:52:40.370071+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
128	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-07 23:56:48.923245+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
129	13	Se activó el usuario brayan .	ACTIVAR	Usuarios	usuarios	16	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:01:07.711401+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
130	13	Se elimino logicamente el usuario brayan .	ELIMINAR	Usuarios	usuarios	16	{"estado": "ACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": false}	2026-07-08 00:01:10.717446+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
131	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 00:11:54.304282+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
132	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 00:15:39.128179+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
133	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 00:17:56.324406+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
134	13	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:21:02.060288+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
135	13	Se activó el almacén ALM-SUP-001.	ACTIVAR	Almacenes	almacenes	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:21:04.107536+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
136	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 00:28:40.917208+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
137	13	Se desactivó el almacén alm-22.	DESACTIVAR	Almacenes	almacenes	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:30:13.281064+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
138	13	Se activó el almacén alm-22.	ACTIVAR	Almacenes	almacenes	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:30:15.219678+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
139	13	Se desactivó el almacén alm-2245.	DESACTIVAR	Almacenes	almacenes	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:33:05.920689+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
140	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 00:38:20.921383+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
141	13	Se activó el almacén alm-2245.	ACTIVAR	Almacenes	almacenes	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:38:27.023434+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
142	13	Se desactivó el almacén alm-2245.	DESACTIVAR	Almacenes	almacenes	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:38:28.863391+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
143	13	Se activó el almacén alm-2245.	ACTIVAR	Almacenes	almacenes	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:38:43.431302+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
144	13	Se elimino logicamente el almacen alm-2245.	ELIMINAR	Almacenes	almacenes	5	{"estado": "ACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": false}	2026-07-08 00:38:45.210413+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
145	13	Se desactivó el almacén ALM-POL-001.	DESACTIVAR	Almacenes	almacenes	2	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:39:49.873425+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
146	13	Se activó el almacén ALM-POL-001.	ACTIVAR	Almacenes	almacenes	2	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:39:51.654537+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
147	13	Se desactivó el proveedor PROV-004.	DESACTIVAR	Proveedores	proveedores	4	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:41:19.916008+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
148	13	Se activó el proveedor PROV-004.	ACTIVAR	Proveedores	proveedores	4	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:41:21.673104+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
149	13	Se desactivó el proveedor PROV-004.	DESACTIVAR	Proveedores	proveedores	4	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:41:31.216792+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
150	13	Se activó el proveedor PROV-004.	ACTIVAR	Proveedores	proveedores	4	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:41:32.935879+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
151	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 00:47:08.913231+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
152	13	Se desactivó el proveedor PROV-22.	DESACTIVAR	Proveedores	proveedores	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:47:31.794819+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
153	13	Se activó el proveedor PROV-22.	ACTIVAR	Proveedores	proveedores	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:47:35.802343+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
154	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 00:51:21.685085+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
155	13	Se desactivó el proveedor PROV-22.	DESACTIVAR	Proveedores	proveedores	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:51:26.877495+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
156	13	Se activó el proveedor PROV-22.	ACTIVAR	Proveedores	proveedores	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:51:28.64603+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
157	13	Se elimino logicamente el proveedor PROV-22.	ELIMINAR	Proveedores	proveedores	5	{"estado": "ACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": false}	2026-07-08 00:51:43.074453+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
158	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 00:56:47.569492+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
159	13	Se desactivó el insumo INS-22.	DESACTIVAR	Insumos	insumos	8	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:57:11.680581+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
160	13	Se activó el insumo INS-22.	ACTIVAR	Insumos	insumos	8	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:57:13.996907+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
161	13	Se elimino logicamente el insumo INS-22.	ELIMINAR	Insumos	insumos	8	{"estado": "ACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": true}	2026-07-08 00:57:16.760306+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
162	13	Se elimino logicamente el insumo INS-007.	ELIMINAR	Insumos	insumos	7	{"estado": "ACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": false}	2026-07-08 00:58:09.584454+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
163	13	Se desactivó el insumo MEC-CTRL-001.	DESACTIVAR	Insumos	insumos	6	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 00:58:39.392203+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
164	13	Se activó el insumo MEC-CTRL-001.	ACTIVAR	Insumos	insumos	6	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 00:58:41.204838+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
165	13	Se creo el pedido PED-20260708-369010.	CREAR	Pedidos	pedidos	6	\N	{"detalles": 1, "prioridad": "URGENTE", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260708-369010", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-08 01:16:09.108054+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	guantes de agua	grandes
166	13	Se aprobo el pedido PED-20260708-369010.	APROBAR	Pedidos	pedidos	6	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "PENDIENTE", "usuarioRevisa": null, "estadoAprobacion": "PENDIENTE"}	2026-07-08 01:16:23.444798+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	perfecto
167	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 01:30:22.116285+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
168	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 01:32:02.223077+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
169	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 02:07:11.689175+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
170	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 02:17:48.429298+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
171	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 02:33:13.625106+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
172	13	Se creo el pedido PED-20260708-054590.	CREAR	Pedidos	pedidos	7	\N	{"detalles": 1, "prioridad": "BAJA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260708-054590", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-08 02:34:14.665381+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	entrega	ninguna
173	13	Se aprobo el pedido PED-20260708-054590.	APROBAR	Pedidos	pedidos	7	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "PENDIENTE", "usuarioRevisa": null, "estadoAprobacion": "PENDIENTE"}	2026-07-08 02:34:48.991029+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	trabajo completado
174	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 02:41:53.070637+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
175	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 02:44:14.975485+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
176	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:01:11.940547+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
177	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:05:37.068459+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
178	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:09:13.980421+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
179	1	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-07-08 03:18:52.538253+00	Localhost (127.0.0.1)	node	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
180	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:24:23.599563+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
181	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:25:24.595745+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
182	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:27:08.074294+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
183	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:36:03.100797+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
184	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:40:33.160269+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
185	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:47:38.573203+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
186	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 03:55:51.458091+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
187	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 04:02:22.530383+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
188	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 04:04:19.376658+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
189	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 04:12:20.061882+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
190	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 04:34:27.255857+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
191	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 04:44:40.387515+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
192	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 04:49:32.31025+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
193	13	Se genero el despacho DES-2026-0004.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	9	\N	{"idPedido": 7, "codigoDespacho": "DES-2026-0004", "estadoDespacho": "ENTREGADO_COMPLETO"}	2026-07-08 04:49:41.010205+00	\N	\N	\N	\N
194	13	Se transfirio stock con referencia TRF-2026-0001.	AJUSTAR_INVENTARIO	Inventario y Despachos	movimientos_inventario	25	\N	{"cantidad": 1, "idInsumo": 1, "idAlmacenOrigen": 1, "codigoReferencia": "TRF-2026-0001", "idAlmacenDestino": 2}	2026-07-08 04:50:58.866658+00	\N	\N	\N	\N
195	13	Se genero el despacho DES-2026-0005.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	10	\N	{"idPedido": 6, "codigoDespacho": "DES-2026-0005", "estadoDespacho": "ENTREGADO_PARCIAL"}	2026-07-08 04:53:20.804239+00	\N	\N	\N	\N
196	13	Se creo el pedido PED-20260708-986116.	CREAR	Pedidos	pedidos	8	\N	{"detalles": 1, "prioridad": "ALTA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260708-986116", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-08 05:03:06.368418+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	operacion	falta de material
218	13	Se desactivó el usuario maria.	DESACTIVAR	Usuarios	usuarios	15	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 18:26:21.901189+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
197	13	Se aprobo el pedido PED-20260708-986116.	APROBAR	Pedidos	pedidos	8	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "PENDIENTE", "usuarioRevisa": null, "estadoAprobacion": "PENDIENTE"}	2026-07-08 05:03:45.363916+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	se aprueba por que se necesita para operadores
198	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 17:16:52.377338+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
199	13	Se desactivó el almacén ALM-POL-001.	DESACTIVAR	Almacenes	almacenes	2	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 17:17:50.659934+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
200	13	Se activó el almacén ALM-POL-001.	ACTIVAR	Almacenes	almacenes	2	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 17:17:52.275721+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
201	13	Se desactivó el proveedor PROV-003.	DESACTIVAR	Proveedores	proveedores	3	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 17:17:59.759835+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
202	13	Se activó el proveedor PROV-003.	ACTIVAR	Proveedores	proveedores	3	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 17:18:01.46381+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
203	1	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-07-08 17:45:57.870615+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
204	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-08 17:46:31.916516+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Safari/537.36	Login correcto	Inicio de sesiÃ³n exitoso.
205	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 17:50:50.161601+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
206	13	Se creo el pedido PED-20260708-164915.	CREAR	Pedidos	pedidos	10	\N	{"detalles": 1, "prioridad": "MEDIA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260708-164915", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-08 17:52:45.049413+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	para trabajo de operación mina	que sea de color blanco
207	13	Se aprobo el pedido PED-20260708-164915.	APROBAR	Pedidos	pedidos	10	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "APROBADO", "usuarioRevisa": 13, "estadoAprobacion": "APROBADO"}	2026-07-08 17:53:36.542307+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	se aprobó porque hay suficiente insumo
208	13	Se genero el despacho DES-2026-0006.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	11	\N	{"idPedido": 10, "codigoDespacho": "DES-2026-0006", "estadoDespacho": "ENTREGADO_COMPLETO"}	2026-07-08 17:55:18.149727+00	\N	\N	\N	\N
209	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 18:07:22.587295+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
210	13	Se creo el pedido PED-20260708-122030.	CREAR	Pedidos	pedidos	12	\N	{"detalles": 1, "prioridad": "URGENTE", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260708-122030", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-08 18:08:42.174391+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	guantes de cuero	\N
211	13	Se aprobo el pedido PED-20260708-122030.	APROBAR	Pedidos	pedidos	12	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "APROBADO", "usuarioRevisa": 13, "estadoAprobacion": "APROBADO"}	2026-07-08 18:09:07.580571+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	se aprobo por cojudo
212	13	Se genero el despacho DES-2026-0007.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	13	\N	{"idPedido": 12, "codigoDespacho": "DES-2026-0007", "estadoDespacho": "ENTREGADO_COMPLETO"}	2026-07-08 18:10:11.024359+00	\N	\N	\N	\N
213	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 18:11:37.594892+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
214	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 18:22:59.357571+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
215	13	Se genero el despacho DES-2026-0008.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	14	\N	{"idPedido": 8, "codigoDespacho": "DES-2026-0008", "estadoDespacho": "ENTREGADO_PARCIAL"}	2026-07-08 18:23:32.654497+00	Localhost (127.0.0.1)	\N	\N	\N
216	13	Se desactivó el almacén ALM-23.	DESACTIVAR	Almacenes	almacenes	4	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 18:24:37.238711+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
217	13	Se activó el almacén ALM-23.	ACTIVAR	Almacenes	almacenes	4	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 18:24:39.246305+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
219	13	Se activó el usuario maria.	ACTIVAR	Usuarios	usuarios	15	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 18:26:23.971088+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
220	13	Se desactivó el proveedor PROV-001.	DESACTIVAR	Proveedores	proveedores	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-08 18:27:22.455446+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
221	13	Se activó el proveedor PROV-001.	ACTIVAR	Proveedores	proveedores	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-08 18:27:24.443061+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
222	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 18:53:59.176774+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
223	13	Se creo el pedido PED-20260708-450595.	CREAR	Pedidos	pedidos	13	\N	{"detalles": 1, "prioridad": "MEDIA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260708-450595", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-08 19:04:10.714139+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	ningua	moded
225	13	Se creo el pedido PED-20260708-053270.	CREAR	Pedidos	pedidos	14	\N	{"detalles": 1, "prioridad": "MEDIA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260708-053270", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-08 19:14:13.480015+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	de recepcion	ninguna
226	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 23:09:17.540627+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
227	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 23:21:28.241636+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
228	13	Se aprobó el pedido PED-20260708-053270 y fue enviado a compras por stock insuficiente.	APROBAR	Pedidos	pedidos	14	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "EN_COMPRA", "usuarioRevisa": 13, "estadoAtencion": "EN_PROCESO", "estadoAprobacion": "APROBADO"}	2026-07-08 23:25:39.582928+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	se realizara una compra
229	13	Se creo el pedido PED-20260708-423244.	CREAR	Pedidos	pedidos	15	\N	{"detalles": 1, "prioridad": "URGENTE", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260708-423244", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-08 23:30:23.434963+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	para trabajo de reparaciones de planta 1, chillar	\N
230	13	Se observó el pedido PED-20260708-423244.	EDITAR	Pedidos	pedidos	15	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "OBSERVADO", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "OBSERVADO", "motivoObservacion": "no se especifica bien que uso se dara"}	2026-07-08 23:31:05.983521+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	no se especifica bien que uso se dara	\N
231	13	Se aprobó el pedido PED-20260708-423244 y fue enviado a compras por stock insuficiente.	APROBAR	Pedidos	pedidos	15	{"estadoPedido": "OBSERVADO", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "OBSERVADO"}	{"estadoPedido": "EN_COMPRA", "usuarioRevisa": 13, "estadoAtencion": "EN_PROCESO", "estadoAprobacion": "APROBADO"}	2026-07-08 23:32:31.376259+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	se aprueba por que se trabajara con todo el personal correspondiente
232	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 23:48:59.074574+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
233	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-08 23:56:59.811045+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
234	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 00:07:05.040267+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
239	13	Se activó el usuario mcondori.	ACTIVAR	Usuarios	usuarios	2	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-09 00:27:42.564213+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
240	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 00:37:03.314914+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
241	13	Se creo el pedido PED-20260709-595518.	CREAR	Pedidos	pedidos	16	\N	{"detalles": 1, "prioridad": "BAJA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-20260709-595518", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-09 00:39:55.805414+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	una orquesta	\N
235	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 00:26:26.52715+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
236	13	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-09 00:27:08.112669+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
237	13	Se activó el almacén ALM-SUP-001.	ACTIVAR	Almacenes	almacenes	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-09 00:27:11.020706+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
238	13	Se desactivó el usuario mcondori.	DESACTIVAR	Usuarios	usuarios	2	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-09 00:27:38.450924+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
245	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 01:06:12.72449+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
246	13	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	13	\N	{}	2026-07-09 01:06:53.807927+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
247	13	Se desactivó el almacén ALM-SUP-001.	DESACTIVAR	Almacenes	almacenes	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-09 01:07:41.014063+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
248	13	Se activó el almacén ALM-SUP-001.	ACTIVAR	Almacenes	almacenes	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-09 01:07:43.68133+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
249	13	Se desactivó el proveedor PROV-001.	DESACTIVAR	Proveedores	proveedores	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-09 01:08:04.607233+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
250	13	Se activó el proveedor PROV-001.	ACTIVAR	Proveedores	proveedores	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-09 01:08:06.839707+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
251	13	Se actualizó un registro en Pedidos.	EDITAR	Pedidos	pedidos	16	\N	{"lugarUso": "taller", "prioridad": "BAJA", "tipoPedido": "URGENTE", "centroCosto": "mina", "turnoGuardia": "dia", "justificacion": "una orquesta", "fechaRequerida": "2026-07-09T12:00:00.000Z"}	2026-07-09 01:10:07.563999+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
252	13	Se observó el pedido PED-20260709-595518.	EDITAR	Pedidos	pedidos	16	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "OBSERVADO", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "OBSERVADO", "motivoObservacion": "no se especifica bien porque"}	2026-07-09 01:10:37.489871+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	no se especifica bien porque	\N
253	13	Se aprobó el pedido PED-20260709-595518.	APROBAR	Pedidos	pedidos	16	{"estadoPedido": "OBSERVADO", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "OBSERVADO"}	{"estadoPedido": "APROBADO", "usuarioRevisa": 13, "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "APROBADO"}	2026-07-09 01:12:05.621875+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
254	13	Se envió el pedido PED-20260709-595518 a preparación de despacho.	EDITAR	Pedidos	pedidos	16	{"estadoPedido": "APROBADO", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "APROBADO"}	{"estadoPedido": "EN_DESPACHO", "estadoAtencion": "EN_PROCESO", "estadoAprobacion": "APROBADO"}	2026-07-09 01:12:29.933553+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
255	13	Se genero el despacho DES-2026-0009.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	15	\N	{"idPedido": 16, "codigoDespacho": "DES-2026-0009", "estadoDespacho": "ENTREGADO_PARCIAL"}	2026-07-09 01:13:10.204147+00	Localhost (127.0.0.1)	\N	\N	\N
256	13	Se genero el despacho DES-2026-0010.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	16	\N	{"idPedido": 16, "codigoDespacho": "DES-2026-0010", "estadoDespacho": "ENTREGADO_COMPLETO"}	2026-07-09 01:15:14.352152+00	Localhost (127.0.0.1)	\N	\N	\N
257	13	Se desactivó el insumo SEG-GUA-001.	DESACTIVAR	Insumos	insumos	2	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-09 01:23:19.765244+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
258	13	Se activó el insumo SEG-GUA-001.	ACTIVAR	Insumos	insumos	2	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-09 01:23:20.840488+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
259	13	Se registro AJUSTE_POSITIVO por 7.	AJUSTAR_INVENTARIO	Inventario y Despachos	movimientos_inventario	34	\N	{"cantidad": 7, "idInsumo": 1, "idAlmacen": 1, "tipoMovimiento": "AJUSTE_POSITIVO"}	2026-07-09 01:30:39.939383+00	\N	\N	\N	\N
260	13	Se transfirio stock con referencia TRF-2026-0002.	AJUSTAR_INVENTARIO	Inventario y Despachos	movimientos_inventario	35	\N	{"cantidad": 4, "idInsumo": 1, "idAlmacenOrigen": 1, "codigoReferencia": "TRF-2026-0002", "idAlmacenDestino": 4}	2026-07-09 01:31:43.045855+00	\N	\N	\N	\N
261	13	Se registro una devolucion por 1.	AJUSTAR_INVENTARIO	Inventario y Despachos	movimientos_inventario	37	\N	{"cantidad": 1, "idInsumo": 1, "idDespacho": 16, "idAlmacenDestino": 1}	2026-07-09 01:32:53.900282+00	\N	\N	\N	\N
262	13	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	27	\N	{}	2026-07-09 01:38:29.848203+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
263	13	Se anuló un registro en Notificaciones.	ANULAR	Notificaciones	notificaciones	27	\N	\N	2026-07-09 01:40:39.87564+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
264	15	Login correcto de maria	INICIAR_SESION	Autenticación	usuarios	15	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "maria"}	2026-07-09 01:53:32.827563+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
265	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 01:56:14.151006+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
266	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-09 01:56:50.311377+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
267	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 01:58:08.466737+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
268	5	Login correcto de lmamani	INICIAR_SESION	Autenticación	usuarios	5	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "lmamani"}	2026-07-09 01:58:34.623282+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
269	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 01:59:22.581959+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
270	3	Login correcto de cquispe	INICIAR_SESION	Autenticación	usuarios	3	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "cquispe"}	2026-07-09 01:59:45.681937+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
271	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 02:01:36.086181+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
272	4	Login correcto de avargas	INICIAR_SESION	Autenticación	usuarios	4	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "avargas"}	2026-07-09 02:01:57.576286+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
273	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 02:02:48.385462+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
274	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 04:20:39.46158+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
275	13	Se genero el despacho DES-2026-0011.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	17	\N	{"idPedido": 14, "codigoDespacho": "DES-2026-0011", "estadoDespacho": "ENTREGADO_PARCIAL"}	2026-07-09 04:29:24.430516+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	por falta de stock se realiza esta entrega
276	13	Se genero el despacho DES-2026-0012.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	18	\N	{"idPedido": 8, "codigoDespacho": "DES-2026-0012", "estadoDespacho": "ENTREGADO_PARCIAL"}	2026-07-09 04:30:54.221861+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	por falta de entrega se realiza esta entrega
277	13	Se registro AJUSTE_NEGATIVO por 2.	AJUSTAR_INVENTARIO	Inventario y Despachos	movimientos_inventario	40	\N	{"cantidad": 2, "idInsumo": 2, "idAlmacen": 1, "tipoMovimiento": "AJUSTE_NEGATIVO"}	2026-07-09 04:41:00.961758+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	por mal registro de inventario	mas seguro al momento de comprar
278	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 04:45:49.880495+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
279	13	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	32	\N	{}	2026-07-09 04:49:33.748709+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
280	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 05:00:17.913736+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
281	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 05:01:33.315096+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
282	13	Se anuló un registro en Notificaciones.	ANULAR	Notificaciones	notificaciones	32	\N	\N	2026-07-09 05:08:21.556343+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
283	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 05:54:49.58376+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
284	13	Se registró una orden de compra en Compras y Comprobantes.	REGISTRAR_COMPRA	Compras y Comprobantes	ordenes_compra	15	\N	{"moneda": "BOB", "detalles": [{"idInsumo": 9, "observacion": "color blanco", "precioUnitario": 80, "cantidadComprada": 12, "cantidadSolicitada": 12}], "idPedido": 15, "impuesto": 0, "descuento": 10, "formaPago": "CHEQUE", "idProveedor": 1, "numeroOrden": "OC-20260709-126838", "condicionPago": "CONTADO", "observaciones": "ninguna", "usuarioGenera": 13, "codigoCorrelativo": "CORR-OC-20260709-126838", "fechaEstimadaEntrega": "2026-07-09"}	2026-07-09 06:05:26.92836+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
285	13	Se registro la recepcion REC-20260709-271389.	REGISTRAR_RECEPCION	Compras y Comprobantes	recepciones_compra	4	\N	{"detalles": 1, "idOrdenCompra": 11, "estadoRecepcion": "RECIBIDA_COMPLETA", "numeroRecepcion": "REC-20260709-271389", "idAlmacenDestino": 1}	2026-07-09 06:07:51.487679+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	trado mucho	gr-3
286	13	Se registró un comprobante de compra en Compras y Comprobantes.	REGISTRAR_COMPROBANTE	Compras y Comprobantes	comprobantes_compra	1	\N	{"moneda": "BOB", "idProveedor": 1, "nitProveedor": "1001001001", "idOrdenCompra": 11, "montoImpuesto": 0, "montoSubtotal": 960, "observaciones": "perfecto", "montoDescuento": 10, "tipoComprobante": "RECIBO", "usuarioRegistra": 13, "fechaComprobante": "2026-07-09", "numeroComprobante": "1"}	2026-07-09 06:09:08.259124+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
287	13	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	34	\N	{}	2026-07-09 06:11:08.396453+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
288	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 14:12:10.622325+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
289	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 14:42:51.299352+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
290	13	Se registro la orden de compra OC-20260709-377821.	REGISTRAR_COMPRA	Compras y Comprobantes	ordenes_compra	12	\N	{"idPedido": 15, "idProveedor": 1, "numeroOrden": "OC-20260709-377821", "estadoCompra": "PENDIENTE", "fechaEmision": "2026-07-09T04:00:00.000Z", "fechaEstimadaEntrega": "2026-07-09T04:00:00.000Z"}	2026-07-09 14:46:17.903414+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	se está realizando la compra para reponer stock del inventario	\N
291	13	Se registró una orden de compra en Compras y Comprobantes.	REGISTRAR_COMPRA	Compras y Comprobantes	ordenes_compra	15	\N	{"moneda": "BOB", "detalles": [{"idInsumo": 9, "observacion": "color blanco", "precioUnitario": 80, "cantidadComprada": 12, "cantidadSolicitada": 12}], "idPedido": 15, "impuesto": 0.5, "descuento": 5, "formaPago": "TRANSFERENCIA", "idProveedor": 1, "numeroOrden": "OC-20260709-377821", "condicionPago": "CONTADO", "observaciones": "se está realizando la compra para reponer stock del inventario", "usuarioGenera": 13, "codigoCorrelativo": "CORR-OC-20260709-377821", "fechaEstimadaEntrega": "2026-07-09T20:00:00.000Z"}	2026-07-09 14:46:17.912918+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
292	13	Se registro la recepcion REC-20260709-540133.	REGISTRAR_RECEPCION	Compras y Comprobantes	recepciones_compra	5	\N	{"detalles": 1, "idOrdenCompra": 12, "estadoRecepcion": "RECIBIDA_COMPLETA", "numeroRecepcion": "REC-20260709-540133", "idAlmacenDestino": 2}	2026-07-09 14:49:00.241808+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	esta perfecto en el insumo pedido	ninguno
293	13	Se registro el comprobante 40.	REGISTRAR_COMPROBANTE	Compras y Comprobantes	comprobantes_compra	5	\N	{"idProveedor": 1, "idOrdenCompra": 12, "tipoComprobante": "RECIBO", "fechaComprobante": "2026-07-09T04:00:00.000Z", "estadoComprobante": "REGISTRADO", "numeroComprobante": "40"}	2026-07-09 14:52:18.928289+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	esta perfecto	\N
294	13	Se registró un comprobante de compra en Compras y Comprobantes.	REGISTRAR_COMPROBANTE	Compras y Comprobantes	comprobantes_compra	1	\N	{"moneda": "BOB", "idProveedor": 1, "nitProveedor": "1001001001", "idOrdenCompra": 12, "montoImpuesto": 0.5, "montoSubtotal": 960, "observaciones": "esta perfecto", "montoDescuento": 5, "tipoComprobante": "RECIBO", "usuarioRegistra": 13, "fechaComprobante": "2026-07-09T14:52:00.000Z", "numeroComprobante": "40"}	2026-07-09 14:52:18.93654+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
295	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 15:04:06.283361+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
296	13	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	35	\N	{}	2026-07-09 15:04:13.487708+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
297	13	Se genero el despacho DES-2026-0013.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	19	\N	{"idPedido": 15, "codigoDespacho": "DES-2026-0013", "estadoDespacho": "ENTREGADO_COMPLETO"}	2026-07-09 15:07:20.12746+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	perfecto
298	13	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	36	\N	{}	2026-07-09 15:08:03.830713+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
299	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 15:14:41.818635+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
300	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 15:22:23.128702+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
301	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 15:23:06.155206+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
302	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 15:33:06.574189+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
303	13	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	13	\N	{}	2026-07-09 15:36:26.405452+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
304	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 15:43:19.501445+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
305	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 20:32:21.196424+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
306	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	13	\N	{"cargo": "presidente de Vigilancia ", "idRol": 1, "correo": "feyckon@gmail.com", "estado": "ACTIVO", "idArea": 6, "telefono": "74477014", "nombreUsuario": "federico", "nombreCompleto": "federico choquecallata villca", "cedulaIdentidad": "12901305 LPAZ "}	2026-07-09 20:34:27.757762+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
307	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	13	\N	{"cargo": "presidente de Vigilancia", "idRol": 1, "correo": "feyckon@gmail.com", "estado": "ACTIVO", "idArea": 6, "telefono": "74477014", "nombreUsuario": "federico", "nombreCompleto": "federico choquecallata villca", "cedulaIdentidad": "12901305 LPAZ"}	2026-07-09 20:35:17.611269+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
308	1	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-07-09 21:12:12.092726+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT; Windows NT 10.0; es-BO) WindowsPowerShell/5.1.26100.8655	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
309	6	Login fallido de pmamani	INICIAR_SESION	Autenticación	usuarios	6	\N	{"motivo": "Usuario inactivo", "resultado": "FALLIDO", "nombreUsuario": "pmamani"}	2026-07-09 21:12:20.362852+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT; Windows NT 10.0; es-BO) WindowsPowerShell/5.1.26100.8655	Usuario inactivo	Intento de inicio de sesiÃ³n no autorizado.
310	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-09 21:12:20.496973+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT; Windows NT 10.0; es-BO) WindowsPowerShell/5.1.26100.8655	Login correcto	Inicio de sesiÃ³n exitoso.
311	13	Login fallido de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Contraseña incorrecta", "resultado": "FALLIDO", "nombreUsuario": "federico"}	2026-07-09 21:12:57.849693+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT; Windows NT 10.0; es-BO) WindowsPowerShell/5.1.26100.8655	Contraseña incorrecta	Intento de inicio de sesiÃ³n no autorizado.
312	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	13	\N	{"expedidoCi": "OR", "complementoCi": "1A", "cedulaIdentidad": "12901305"}	2026-07-09 21:13:52.026304+00	Localhost (127.0.0.1)	node	\N	\N
313	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-09 21:15:51.088213+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
314	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	13	\N	{"cargo": "presidente de Vigilancia", "idRol": 1, "correo": "feyckon@gmail.com", "estado": "ACTIVO", "idArea": 6, "telefono": "74477014", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "federico", "nombreCompleto": "federico choquecallata villca", "cedulaIdentidad": "12901305"}	2026-07-09 21:16:28.42155+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
315	13	Se desactivó el usuario maria.	DESACTIVAR	Usuarios	usuarios	15	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-09 21:19:12.794617+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
316	13	Se activó el usuario maria.	ACTIVAR	Usuarios	usuarios	15	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-09 21:19:14.732651+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
317	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	15	\N	{"cargo": "auditor interno de administracion", "idRol": 6, "correo": "maria@gmail.com", "estado": "ACTIVO", "idArea": 16, "telefono": "74717475", "expedidoCi": "LP", "complementoCi": "1A", "nombreUsuario": "maria", "nombreCompleto": "maria gutierrez beltran", "cedulaIdentidad": "12345678"}	2026-07-09 21:20:39.829622+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
318	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	5	\N	{"cargo": "Técnico de mantenimiento", "idRol": 7, "correo": "lmamani@mineria.local", "estado": "ACTIVO", "idArea": 2, "telefono": "70000005", "expedidoCi": "LP", "complementoCi": null, "nombreUsuario": "lmamani", "nombreCompleto": "Luis Mamani Flores", "cedulaIdentidad": "23456789"}	2026-07-09 21:24:01.325996+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
319	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	5	\N	{"cargo": "Técnico de mantenimiento", "idRol": 7, "correo": "lmamani@mineria.local", "estado": "ACTIVO", "idArea": 1, "telefono": "70000005", "expedidoCi": "LP", "complementoCi": null, "nombreUsuario": "lmamani", "nombreCompleto": "Luis Mamani Flores", "cedulaIdentidad": "23456789"}	2026-07-09 21:24:13.135784+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
320	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	4	\N	{"cargo": "Encargada de compras", "idRol": 5, "correo": "avargas@mineria.local", "estado": "ACTIVO", "idArea": 4, "telefono": "70000004", "expedidoCi": "BN", "complementoCi": null, "nombreUsuario": "avargas", "nombreCompleto": "Ana Vargas Choque", "cedulaIdentidad": "12913568"}	2026-07-09 21:24:45.968987+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
321	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	3	\N	{"cargo": "Supervisor de mina", "idRol": 4, "correo": "cquispe@mineria.local", "estado": "ACTIVO", "idArea": 1, "telefono": "70000003", "expedidoCi": "LP", "complementoCi": "2A", "nombreUsuario": "cquispe", "nombreCompleto": "Carlos Quispe Mamani", "cedulaIdentidad": "1265896"}	2026-07-09 21:25:08.831405+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
322	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	2	\N	{"cargo": "Jefe de almacén", "idRol": 2, "correo": "mcondori@mineria.local", "estado": "ACTIVO", "idArea": 5, "telefono": "70000002", "expedidoCi": "LP", "complementoCi": null, "nombreUsuario": "mcondori", "nombreCompleto": "María Condori Alarcón", "cedulaIdentidad": "12369574"}	2026-07-09 21:25:25.789222+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
323	15	Login correcto de maria	INICIAR_SESION	Autenticación	usuarios	15	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "maria"}	2026-07-09 21:32:51.528075+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
324	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 17:56:38.143947+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
325	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 18:21:47.125257+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
326	13	Se creó un nuevo registro en Usuarios.	CREAR	Usuarios	usuarios	17	\N	{"cargo": null, "idRol": 7, "correo": "duki@gmail.com", "estado": "INACTIVO", "idArea": 8, "telefono": "57486814", "expedidoCi": "LP", "complementoCi": null, "nombreUsuario": "wdefevtbryrb", "nombreCompleto": "efwrebtryntumyynrtbwecs", "cedulaIdentidad": "546154815"}	2026-07-14 18:41:06.481242+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
327	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	17	\N	{"cargo": null, "idRol": 7, "correo": "duki@gmail.com", "estado": "INACTIVO", "idArea": 8, "telefono": "57486814", "expedidoCi": null, "complementoCi": null, "nombreUsuario": "wdefevtbryrb", "nombreCompleto": "efwrebtryntumyynrtbwecs", "cedulaIdentidad": "546154815"}	2026-07-14 18:41:17.142675+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
328	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	17	\N	{"cargo": null, "idRol": 7, "correo": "duki@gmail.com", "estado": "INACTIVO", "idArea": 8, "telefono": "57486814", "expedidoCi": null, "complementoCi": null, "nombreUsuario": "wdefevtbryrb", "nombreCompleto": "efwrebtryntumyynrtbwecs", "cedulaIdentidad": "546154815"}	2026-07-14 18:43:18.706876+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
329	13	Se elimino logicamente el usuario wdefevtbryrb.	ELIMINAR	Usuarios	usuarios	17	{"estado": "INACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": false}	2026-07-14 18:46:27.865621+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
330	13	Se actualizó un registro en Almacenes.	EDITAR	Almacenes	almacenes	4	\N	{"ubicacion": "INTERIOR MINA", "descripcion": "ingreso de insumos nivel 70", "idEncargado": 2, "tipoAlmacen": "TEMPORAL", "codigoAlmacen": "ALM-23", "nombreAlmacen": "ALMACEN SUPERFICIE 2", "horarioAtencion": "08:00-10:00", "telefonoContacto": "74477014"}	2026-07-14 18:47:51.208995+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
331	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 20:27:22.58039+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
332	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 20:59:57.492772+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
333	13	Se desactivó el usuario maria.	DESACTIVAR	Usuarios	usuarios	15	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-14 21:03:50.066505+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
334	13	Se activó el usuario maria.	ACTIVAR	Usuarios	usuarios	15	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-14 21:03:52.053226+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
335	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 21:22:46.102186+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
336	13	Se creó un nuevo registro en Usuarios.	CREAR	Usuarios	usuarios	18	\N	{"cargo": null, "idRol": 7, "correo": "feyckon1@gmail.com", "estado": "ACTIVO", "idArea": 8, "telefono": "75847584", "expedidoCi": "CB", "complementoCi": null, "nombreUsuario": "federico1", "nombreCompleto": "federico choquecalata zuares", "cedulaIdentidad": "12345675"}	2026-07-14 21:27:19.876497+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
337	13	Se elimino logicamente el usuario federico1.	ELIMINAR	Usuarios	usuarios	18	{"estado": "ACTIVO"}	{"estado": "ELIMINADO", "tieneRelaciones": false}	2026-07-14 21:27:41.865976+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
338	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 21:59:33.461365+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
339	13	Se creo el pedido PED-0001/2026.	CREAR	Pedidos	pedidos	17	\N	{"detalles": 1, "prioridad": "BAJA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-0001/2026", "idAreaSolicitante": 6, "idUsuarioSolicitante": 13}	2026-07-14 22:04:36.936876+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Mantenimiento programado	\N
340	13	Se aprobó el pedido PED-0001/2026.	APROBAR	Pedidos	pedidos	17	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "APROBADO", "usuarioRevisa": 13, "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "APROBADO"}	2026-07-14 22:08:31.173843+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	se prueba por que se hara mantenimiento de molino 3
341	13	Se envió el pedido PED-0001/2026 a preparación de despacho.	EDITAR	Pedidos	pedidos	17	{"estadoPedido": "APROBADO", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "APROBADO"}	{"estadoPedido": "EN_DESPACHO", "estadoAtencion": "EN_PROCESO", "estadoAprobacion": "APROBADO"}	2026-07-14 22:08:54.978629+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
342	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 22:13:36.680804+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
343	15	Login correcto de maria	INICIAR_SESION	Autenticación	usuarios	15	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "maria"}	2026-07-14 23:08:34.47473+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
345	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 23:10:26.71701+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
346	13	Se desactivó el usuario maria.	DESACTIVAR	Usuarios	usuarios	15	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-14 23:10:41.290017+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
347	13	Se activó el usuario maria.	ACTIVAR	Usuarios	usuarios	15	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-14 23:10:43.057819+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
348	3	Login correcto de cquispe	INICIAR_SESION	Autenticación	usuarios	3	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "cquispe"}	2026-07-14 23:11:34.344067+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
365	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 23:12:03.948738+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
366	4	Login correcto de avargas	INICIAR_SESION	Autenticación	usuarios	4	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "avargas"}	2026-07-14 23:12:23.097159+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
368	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 23:15:43.13229+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
369	13	Se desactivó el proveedor PROV-001.	DESACTIVAR	Proveedores	proveedores	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-14 23:16:29.511842+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
370	13	Se activó el proveedor PROV-001.	ACTIVAR	Proveedores	proveedores	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-14 23:16:31.010265+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
486	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-14 23:57:52.894548+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
371	13	Se actualizó un registro en Proveedores.	EDITAR	Proveedores	proveedores	4	\N	{"nit": "1020304050", "rubro": "HERRAMIENTAS_REPUESTOS", "ciudad": "Tarija", "correo": "ventas@ferromin.com", "telefono": "252099999", "razonSocial": "Ferretería Industrial Oruro S.R.L.", "celularWhatsapp": "70000999", "codigoProveedor": "PROV-004", "nombreComercial": "FerroMin Oruro", "personaContacto": "Carlos Rojas", "tipoInsumosProvee": "Herramientas manuales, repuestos y equipos menores"}	2026-07-14 23:16:50.868303+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
372	13	Se desactivó el insumo SEG-CAS-001.	DESACTIVAR	Insumos	insumos	1	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-14 23:17:00.143469+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
373	13	Se activó el insumo SEG-CAS-001.	ACTIVAR	Insumos	insumos	1	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-14 23:17:02.410597+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
374	3	Login correcto de cquispe	INICIAR_SESION	Autenticación	usuarios	3	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "cquispe"}	2026-07-14 23:19:37.594215+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
424	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 23:26:55.226561+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
425	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-14 23:27:27.057497+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
430	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 23:28:31.195582+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
431	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-14 23:29:05.275188+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
433	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 23:29:44.558292+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
434	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-14 23:29:59.750986+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
435	13	Se creó un nuevo registro en Usuarios.	CREAR	Usuarios	usuarios	19	\N	{"cargo": null, "idRol": 3, "correo": "juve@gmail.com", "estado": "ACTIVO", "idArea": 5, "telefono": "74477171", "expedidoCi": "LP", "complementoCi": null, "nombreUsuario": "juve", "nombreCompleto": "juvenal choquecallata villca", "cedulaIdentidad": "23456782"}	2026-07-14 23:32:16.816688+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
436	19	Login correcto de juve	INICIAR_SESION	Autenticación	usuarios	19	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "juve"}	2026-07-14 23:32:30.543335+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
438	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 23:33:02.065411+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
449	4	Login correcto de avargas	INICIAR_SESION	Autenticación	usuarios	4	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "avargas"}	2026-07-14 23:39:02.425391+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
470	\N	Login fallido de imamani	INICIAR_SESION	Autenticación	usuarios	\N	\N	{"motivo": "Usuario no encontrado", "resultado": "FALLIDO", "nombreUsuario": "imamani"}	2026-07-14 23:45:21.85682+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Usuario no encontrado	Intento de inicio de sesiÃ³n no autorizado.
471	5	Login correcto de lmamani	INICIAR_SESION	Autenticación	usuarios	5	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "lmamani"}	2026-07-14 23:45:29.924865+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
478	15	Login correcto de maria	INICIAR_SESION	Autenticación	usuarios	15	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "maria"}	2026-07-14 23:47:34.094936+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
481	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-14 23:55:58.184292+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
482	19	Login correcto de juve	INICIAR_SESION	Autenticación	usuarios	19	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "juve"}	2026-07-14 23:56:36.259021+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
492	2	Login fallido de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Contraseña incorrecta", "resultado": "FALLIDO", "nombreUsuario": "mcondori"}	2026-07-15 00:02:19.9022+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Contraseña incorrecta	Intento de inicio de sesiÃ³n no autorizado.
493	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-15 00:02:29.014398+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
494	19	Login correcto de juve	INICIAR_SESION	Autenticación	usuarios	19	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "juve"}	2026-07-15 00:02:56.162572+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
503	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 00:48:46.963407+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
504	2	Login correcto de mcondori	INICIAR_SESION	Autenticación	usuarios	2	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "mcondori"}	2026-07-15 00:51:38.182676+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
508	3	Login correcto de cquispe	INICIAR_SESION	Autenticación	usuarios	3	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "cquispe"}	2026-07-15 00:52:44.617591+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
525	13	Login fallido de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Contraseña incorrecta", "resultado": "FALLIDO", "nombreUsuario": "federico"}	2026-07-15 01:14:00.232513+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Contraseña incorrecta	Intento de inicio de sesiÃ³n no autorizado.
526	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 01:14:06.263512+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
527	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 01:20:26.620403+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
528	3	Login correcto de cquispe	INICIAR_SESION	Autenticación	usuarios	3	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "cquispe"}	2026-07-15 01:21:04.283232+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
531	19	Login correcto de juve	INICIAR_SESION	Autenticación	usuarios	19	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "juve"}	2026-07-15 01:23:40.568189+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
533	19	Login correcto de juve	INICIAR_SESION	Autenticación	usuarios	19	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "juve"}	2026-07-15 01:25:24.848091+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
535	4	Login correcto de avargas	INICIAR_SESION	Autenticación	usuarios	4	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "avargas"}	2026-07-15 01:28:09.135378+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
536	5	Login correcto de lmamani	INICIAR_SESION	Autenticación	usuarios	5	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "lmamani"}	2026-07-15 01:32:46.99675+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
537	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 01:51:36.889998+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
538	13	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	13	\N	{}	2026-07-15 01:54:14.065781+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
539	13	Se anuló un registro en Notificaciones.	ANULAR	Notificaciones	notificaciones	38	\N	\N	2026-07-15 01:54:23.183611+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
540	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 02:02:33.050424+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
541	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 02:20:31.315625+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
542	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	3	\N	{"cargo": "Supervisor de mina", "idRol": 4, "correo": "cquispe@mineria.local", "estado": "ACTIVO", "idArea": 1, "telefono": "70000003", "expedidoCi": "LP", "complementoCi": "2A", "nombreUsuario": "cquispe", "nombreCompleto": "Carlos Quispe Mamani", "cedulaIdentidad": "1265896"}	2026-07-15 02:20:42.246636+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
543	13	Se desactivó el usuario cquispe.	DESACTIVAR	Usuarios	usuarios	3	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-15 02:20:44.876041+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
544	13	Se activó el usuario cquispe.	ACTIVAR	Usuarios	usuarios	3	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-15 02:20:47.804941+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
545	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 02:31:17.060985+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
546	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 02:36:50.613444+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
547	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 02:40:19.222513+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
548	13	Se desactivó el usuario lmamani.	DESACTIVAR	Usuarios	usuarios	5	{"estado": "ACTIVO"}	{"estado": "INACTIVO"}	2026-07-15 02:40:37.621952+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
549	13	Se activó el usuario lmamani.	ACTIVAR	Usuarios	usuarios	5	{"estado": "INACTIVO"}	{"estado": "ACTIVO"}	2026-07-15 02:40:40.252205+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
550	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 02:49:51.251403+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
551	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 03:06:21.457999+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
552	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 18:05:30.048968+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
553	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 18:22:46.281014+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
554	13	Se actualizó un registro en Almacenes.	EDITAR	Almacenes	almacenes	4	\N	{"ubicacion": "INTERIOR MINA", "descripcion": "ingreso de insumos nivel 70", "idEncargado": 2, "tipoAlmacen": "TEMPORAL", "codigoAlmacen": "ALM-23", "nombreAlmacen": "ALMACEN SUPERFICIE 2", "horarioAtencion": "08:00-10:00", "telefonoContacto": "74477014"}	2026-07-15 18:23:36.614583+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
555	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 18:33:00.005928+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
556	13	Se actualizó un registro en Proveedores.	EDITAR	Proveedores	proveedores	1	\N	{"nit": "1001001001", "rubro": "HERRAMIENTAS_REPUESTOS", "ciudad": "Oruro", "correo": "ventas@suministrosandinos.local", "telefono": "25250001", "razonSocial": "Suministros Andinos S.R.L.", "celularWhatsapp": "72000001", "codigoProveedor": "PROV-001", "nombreComercial": "Suministros Andinos", "personaContacto": "Roberto Salazar", "tipoInsumosProvee": "Herramientas, EPP, repuestos y material de perforación"}	2026-07-15 18:34:46.59405+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
557	13	Se actualizó un registro en Proveedores.	EDITAR	Proveedores	proveedores	1	\N	{"nit": "1001001001", "rubro": "HERRAMIENTAS_REPUESTOS", "ciudad": "Oruro", "correo": "ventas@suministrosandinos.local", "telefono": "25250001", "razonSocial": "Suministros Andinos S.R.L.", "celularWhatsapp": "72000021", "codigoProveedor": "PROV-001", "nombreComercial": "Suministros Andinos", "personaContacto": "Roberto Salazar", "tipoInsumosProvee": "Herramientas, EPP, repuestos y material de perforación"}	2026-07-15 18:34:56.626237+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
558	13	Se actualizó un registro en Insumos.	EDITAR	Insumos	insumos	1	\N	{"descripcion": "Casco de seguridad para personal de operación mina. superficie", "idCategoria": 2, "stockMinimo": 11, "idTipoInsumo": 4, "nombreInsumo": "Casco de seguridad minero 1", "codigoInterno": "SEG-CAS001", "idUnidadMedida": 1, "precioReferencial": 85}	2026-07-15 18:35:23.628037+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
559	13	Se actualizó un registro en Almacenes.	EDITAR	Almacenes	almacenes	1	\N	{"ubicacion": "Zona administrativa de superficie", "descripcion": "Almacén principal de insumos generales.", "idEncargado": 3, "tipoAlmacen": "SUPERFICIE", "codigoAlmacen": "ALM-SUP001", "nombreAlmacen": "Almacén de superficie", "horarioAtencion": "Lunes a sábado 08:00 - 18:00", "telefonoContacto": "70000002"}	2026-07-15 18:37:04.983435+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
560	13	Se actualizó un registro en Almacenes.	EDITAR	Almacenes	almacenes	1	\N	{"ubicacion": "Zona administrativa de superficie", "descripcion": "Almacén principal de insumos generales.", "idEncargado": 3, "tipoAlmacen": "SUPERFICIE", "codigoAlmacen": "ALM-SUP-1", "nombreAlmacen": "Almacén de superficie", "horarioAtencion": "Lunes a sábado 08:00 - 18:00", "telefonoContacto": "70000002"}	2026-07-15 18:37:36.039603+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
561	13	Se actualizó un registro en Almacenes.	EDITAR	Almacenes	almacenes	1	\N	{"ubicacion": "Zona administrativa de superficie", "descripcion": "Almacén principal de insumos generales.", "idEncargado": 2, "tipoAlmacen": "SUPERFICIE", "codigoAlmacen": "ALM-SUP-1", "nombreAlmacen": "Almacén de superficie", "horarioAtencion": "Lunes a sábado 08:00 - 18:00", "telefonoContacto": "70000002"}	2026-07-15 18:37:44.296617+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
562	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	2	\N	{"cargo": "Jefe de almacén", "idRol": 2, "correo": "mcondori@mineria.local", "estado": "ACTIVO", "idArea": 5, "telefono": "70000002", "expedidoCi": "LP", "complementoCi": "AJ", "nombreUsuario": "mcondori", "nombreCompleto": "María Condori Alarcón", "cedulaIdentidad": "12369574"}	2026-07-15 18:39:35.881353+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
563	13	Se actualizó un registro en Insumos.	EDITAR	Insumos	insumos	1	\N	{"descripcion": "Casco de seguridad para personal de operación mina. superficie", "idCategoria": 2, "stockMinimo": 11, "idTipoInsumo": 4, "nombreInsumo": "Casco de seguridad minero 1", "codigoInterno": "SEG-1", "idUnidadMedida": 1, "precioReferencial": 85}	2026-07-15 18:41:10.930272+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
564	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 19:08:46.909292+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
565	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	2	\N	{"cargo": "Jefe de almacén", "idRol": 2, "correo": "mcondori@mineria.local", "estado": "ACTIVO", "idArea": 5, "telefono": "70000002", "expedidoCi": "LP", "complementoCi": null, "nombreUsuario": "mcondori", "nombreCompleto": "María Condori Alarcón", "cedulaIdentidad": "12369574"}	2026-07-15 19:08:54.557566+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
566	13	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	2	\N	{"cargo": "Jefe de almacén", "idRol": 2, "correo": "mcondori@mineria.local", "estado": "ACTIVO", "idArea": 5, "telefono": "70000002", "expedidoCi": "CB", "complementoCi": null, "nombreUsuario": "mcondori", "nombreCompleto": "María Condori Alarcón", "cedulaIdentidad": "1236957"}	2026-07-15 19:09:43.831704+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
567	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 19:26:34.400173+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
568	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 19:53:07.386306+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
569	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 20:00:09.536372+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
570	13	Se actualizó un registro en Almacenes.	EDITAR	Almacenes	almacenes	2	\N	{"ubicacion": "Zona segura y aislada de operación", "descripcion": "Almacén para material controlado.", "idEncargado": 2, "tipoAlmacen": "POLVORIN", "codigoAlmacen": "ALM-POL-01", "nombreAlmacen": "Polvorín principal", "horarioAtencion": "Bajo autorización", "telefonoContacto": "70000002"}	2026-07-15 20:00:48.37687+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	\N	\N
571	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 20:06:33.932428+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
572	13	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	13	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-07-15 20:20:43.855689+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
\.


--
-- Data for Name: categorias_insumo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorias_insumo (id_categoria, nombre_categoria, descripcion, estado, fecha_creacion, creado_por) FROM stdin;
1	Herramientas y repuestos	Herramientas, piezas y repuestos de apoyo a la operación mina.	ACTIVO	2026-07-04 13:59:53.677794+00	1
2	Seguridad industrial	Elementos de protección personal y seguridad ocupacional.	ACTIVO	2026-07-04 13:59:53.677794+00	1
3	Lubricantes	Aceites, grasas y lubricantes para mantenimiento.	ACTIVO	2026-07-04 13:59:53.677794+00	1
4	Combustible	Combustible utilizado en equipos y operación.	ACTIVO	2026-07-04 13:59:53.677794+00	1
5	Material de perforación	Materiales e insumos utilizados en perforación.	ACTIVO	2026-07-04 13:59:53.677794+00	1
6	Material explosivo controlado	Material controlado que requiere registro y almacenamiento especial.	ACTIVO	2026-07-04 13:59:53.677794+00	1
\.


--
-- Data for Name: comprobantes_compra; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comprobantes_compra (id_comprobante, numero_comprobante, tipo_comprobante, fecha_comprobante, id_proveedor, nit_proveedor, id_orden_compra, monto_subtotal, monto_descuento, monto_impuesto, moneda, estado_comprobante, archivo_comprobante, observaciones, usuario_registra, fecha_creacion) FROM stdin;
1	FAC-000001	FACTURA	2026-07-05	1	1001001001	1	660.00	0.00	0.00	BOB	REGISTRADO	factura_000001.pdf	Factura registrada correctamente.	4	2026-07-04 13:59:53.677794+00
2	FAC-000002	FACTURA	2026-07-06	1	1001001001	2	2900.00	0.00	0.00	BOB	REGISTRADO	factura_000002.pdf	Factura registrada correctamente.	4	2026-07-04 13:59:53.677794+00
3	FAC-000003	FACTURA	2026-07-06	2	1001001002	3	1900.00	0.00	0.00	BOB	REGISTRADO	factura_000003.pdf	Factura registrada correctamente.	4	2026-07-04 13:59:53.677794+00
4	1	RECIBO	2026-07-08	1	1001001001	11	960.00	10.00	0.00	BOB	REGISTRADO	\N	perfecto	13	2026-07-09 06:09:08.251312+00
5	40	RECIBO	2026-07-09	1	1001001001	12	960.00	5.00	0.50	BOB	REGISTRADO	\N	esta perfecto	13	2026-07-09 14:52:18.91277+00
\.


--
-- Data for Name: despacho_detalles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.despacho_detalles (id_despacho_detalle, id_despacho, id_insumo, cantidad_solicitada, cantidad_aprobada, cantidad_entregada, estado_conformidad, observacion) FROM stdin;
1	1	1	20.00	20.00	20.00	CONFORME	Entrega conforme.
2	1	2	60.00	60.00	60.00	CONFORME	Entrega conforme.
3	2	4	15.00	15.00	15.00	CONFORME	Entrega conforme.
4	3	3	100.00	100.00	100.00	CONFORME	Entrega conforme.
10	9	2	5.00	5.00	5.00	CONFORME	ninguna
11	10	2	2.00	2.00	1.00	CONFORME	ninguna
12	11	1	5.00	5.00	5.00	CONFORME	color blanco
14	13	2	50.00	50.00	50.00	CONFORME	que sea lo mas antes posible
15	14	2	300.00	300.00	30.00	CONFORME	que sea de 1era
16	15	5	10.00	10.00	8.00	CONFORME	que sea en galones
17	16	5	10.00	2.00	2.00	CONFORME	que sea en galones
18	17	1	1000.00	1000.00	2.00	CONFORME	ninguna
19	18	2	300.00	270.00	67.00	CONFORME	que sea de 1era
20	19	9	12.00	12.00	12.00	CONFORME	color blanco
\.


--
-- Data for Name: despachos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.despachos (id_despacho, numero_despacho, id_pedido, id_area_solicitante, id_usuario_solicitante, id_almacen_salida, id_responsable_almacen, persona_recibe, fecha_programada_entrega, fecha_real_entrega, tipo_despacho, estado_despacho, confirmacion_recepcion, evidencia_entrega, observaciones, usuario_registra, fecha_creacion) FROM stdin;
1	DES-2026-0001	1	1	3	1	2	Carlos Quispe Mamani	2026-07-06	2026-07-06 04:00:00+00	NORMAL	ENTREGADO_COMPLETO	t	evidencia_des_0001.pdf	Despacho completo de EPP.	2	2026-07-04 13:59:53.677794+00
2	DES-2026-0002	2	8	3	1	2	Carlos Quispe Mamani	2026-07-07	2026-07-07 04:00:00+00	URGENTE	ENTREGADO_COMPLETO	t	evidencia_des_0002.pdf	Despacho completo de brocas.	2	2026-07-04 13:59:53.677794+00
3	DES-2026-0003	3	2	5	1	2	Luis Mamani Flores	2026-07-08	2026-07-08 04:00:00+00	NORMAL	ENTREGADO_COMPLETO	t	evidencia_des_0003.pdf	Despacho completo de aceite.	2	2026-07-04 13:59:53.677794+00
9	DES-2026-0004	7	6	13	1	13	federico choquecallata villca	\N	2026-07-08 04:00:00+00	NORMAL	ENTREGADO_COMPLETO	t	\N	\N	13	2026-07-08 04:49:40.909672+00
10	DES-2026-0005	6	6	13	1	13	federico choquecallata villca	\N	2026-07-08 04:00:00+00	NORMAL	ENTREGADO_PARCIAL	t	\N	\N	13	2026-07-08 04:53:20.676855+00
11	DES-2026-0006	10	6	13	1	13	federico choquecallata villca	\N	2026-07-08 04:00:00+00	NORMAL	ENTREGADO_COMPLETO	t	\N	\N	13	2026-07-08 17:55:18.004902+00
13	DES-2026-0007	12	6	13	1	13	federico choquecallata villca	\N	2026-07-08 04:00:00+00	NORMAL	ENTREGADO_COMPLETO	t	\N	se esta despachando el pedido por seguridad de los trabajadores	13	2026-07-08 18:10:10.864923+00
14	DES-2026-0008	8	6	13	1	13	federico choquecallata villca	\N	2026-07-08 04:00:00+00	NORMAL	ENTREGADO_PARCIAL	t	\N	\N	13	2026-07-08 18:23:32.449482+00
15	DES-2026-0009	16	6	13	3	13	federico choquecallata villca	\N	2026-07-08 04:00:00+00	NORMAL	ENTREGADO_PARCIAL	t	\N	\N	13	2026-07-09 01:13:10.099049+00
16	DES-2026-0010	16	6	13	3	13	federico choquecallata villca	\N	2026-07-08 04:00:00+00	NORMAL	ENTREGADO_COMPLETO	t	\N	que se uso de manera correcta	13	2026-07-09 01:15:14.238231+00
17	DES-2026-0011	14	6	13	1	13	federico choquecallata villca	\N	2026-07-09 04:29:24.355+00	NORMAL	ENTREGADO_PARCIAL	t	\N	por falta de stock se realiza esta entrega	13	2026-07-09 04:29:24.278846+00
18	DES-2026-0012	8	6	13	1	13	federico choquecallata villca	\N	2026-07-09 04:30:54.147+00	NORMAL	ENTREGADO_PARCIAL	t	\N	por falta de entrega se realiza esta entrega	13	2026-07-09 04:30:54.0753+00
19	DES-2026-0013	15	6	13	1	13	federico choquecallata villca	\N	2026-07-09 15:07:20.058+00	NORMAL	ENTREGADO_COMPLETO	t	\N	perfecto	13	2026-07-09 15:07:19.963286+00
\.


--
-- Data for Name: insumos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.insumos (id_insumo, id_categoria, id_tipo_insumo, id_unidad_medida, id_unidad_medida_secundaria, codigo_interno, codigo_barra_qr, nombre_insumo, descripcion, marca, modelo, presentacion, precio_referencial, ubicacion_sugerida, requiere_control_especial, es_peligroso_inflamable, fecha_vencimiento, imagen_url, ficha_tecnica_url, estado, observaciones, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por, stock_minimo) FROM stdin;
8	5	1	1	\N	INS-22	\N	BARRENO PUNTA DIAMANTE	BARRENO PUNTA DIAMANTE PARA PERFORAZON ROCA NIVEL -70	\N	\N	\N	0.00	\N	f	f	\N	\N	\N	ELIMINADO	\N	2026-07-07 19:33:52.424007+00	2026-07-07 20:57:16.742+00	\N	\N	0.00
7	5	1	1	\N	INS-007	QR-INS-007	Broca de perforación 38 mm	Broca utilizada para trabajos de perforación en interior mina.	Sandvik	B38	Unidad individual	275.00	Estante B-1, almacén de herramientas	f	f	2027-12-30	https://servidor.local/imagenes/broca.png	https://servidor.local/fichas/broca.pdf	ELIMINADO	Precio actualizado según proveedor.	2026-07-04 19:11:03.306611+00	2026-07-07 20:58:09.571+00	\N	\N	0.00
4	5	3	1	\N	PER-BRO-038	QR-PER-BRO-038	Broca de perforación 38 mm	Broca utilizada para trabajos de perforación.	Genérico	38 mm	Unidad	145.00	Estante PER-01	f	f	\N	\N	\N	ACTIVO	Controlar desgaste y reposición.	2026-07-04 13:59:53.677794+00	\N	1	\N	5.00
5	4	5	3	\N	COM-DIE-001	QR-COM-DIE-001	Diésel para operación mina	Combustible utilizado en equipos de operación.	Genérico	Diésel	Litro	6.80	Tanque COM-01	t	t	\N	\N	\N	ACTIVO	Producto inflamable con control especial.	2026-07-04 13:59:53.677794+00	\N	1	\N	300.00
6	6	6	5	\N	MEC-CTRL-001	QR-MEC-CTRL-001	Material explosivo controlado tipo E	Material controlado para operación mina sujeto a autorización.	Controlado	Tipo E	Caja	520.00	Polvorín principal	t	t	\N	\N	\N	ACTIVO	Requiere autorización, registro y trazabilidad estricta.	2026-07-04 13:59:53.677794+00	2026-07-07 20:58:41.186+00	1	\N	5.00
3	3	1	3	\N	LUB-ACE-001	QR-LUB-ACE-001	Aceite lubricante 15W40	Aceite lubricante para equipos de operación y mantenimiento.	Genérico	15W40	Bidón / litro	38.00	Zona lubricantes	f	t	\N	\N	\N	ACTIVO	Mantener en zona ventilada.	2026-07-04 13:59:53.677794+00	2026-07-07 01:47:28.896+00	1	\N	30.00
2	2	4	2	\N	SEG-GUA-001	QR-SEG-GUA-001	Guantes de cuero reforzado	Guantes de protección para trabajos operativos.	Genérico	Reforzado	Par	25.00	Estante EPP-02	f	f	\N	\N	\N	ACTIVO	Uso en mantenimiento y operación.	2026-07-04 13:59:53.677794+00	2026-07-09 01:23:20.833+00	1	\N	20.00
9	2	2	1	\N	INS-2002	\N	CASCO DE SULDARURA	caso de Soldadura para la protection de los trabajadores ya sea ingenio como socavón	\N	\N	\N	80.00	\N	f	f	\N	\N	\N	ACTIVO	\N	2026-07-08 18:30:31.565005+00	2026-07-09 05:48:16.75825+00	\N	\N	10.00
1	2	4	1	\N	SEG-1	QR-SEG-CAS-001	Casco de seguridad minero 1	Casco de seguridad para personal de operación mina. superficie	Genérico	Minero estándar	Unidad	85.00	Estante EPP-01	f	f	\N	\N	\N	ACTIVO	Uso obligatorio en operación.	2026-07-04 13:59:53.677794+00	2026-07-15 18:41:10.906+00	1	\N	11.00
\.


--
-- Data for Name: inventarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inventarios (id_inventario, id_insumo, id_almacen, stock_fisico, stock_reservado, costo_promedio, lote, numero_serie, fecha_vencimiento, ubicacion_interna, estado_stock, fecha_ultima_actualizacion, creado_por, actualizado_por) FROM stdin;
6	6	2	10.00	0.00	500.00	INI-2026-01	\N	\N	POL-01	DISPONIBLE	2026-07-08 18:04:11.273564+00	1	\N
4	4	1	10.00	0.00	144.00	INI-2026-01	\N	\N	PER-01	DISPONIBLE	2026-07-08 18:04:11.273564+00	1	2
3	3	1	30.00	0.00	36.77	INI-2026-01	\N	\N	LUB-01	DISPONIBLE	2026-07-08 18:04:11.273564+00	1	2
11	1	2	1.00	0.00	80.00	\N	\N	\N	\N	DISPONIBLE	2026-07-08 18:04:11.273564+00	13	13
13	9	2	12.00	0.00	80.00	\N	\N	\N	\N	DISPONIBLE	2026-07-09 14:49:00.193686+00	13	\N
12	9	1	0.00	0.00	80.00	\N	\N	\N	\N	AGOTADO	2026-07-09 15:07:19.963286+00	13	13
5	5	3	490.00	0.00	6.50	INI-2026-01	\N	\N	TANQUE-01	DISPONIBLE	2026-07-09 01:15:14.313+00	1	13
2	2	1	565.00	209.00	22.00	INI-2026-01	\N	\N	EPP-02	RESERVADO	2026-07-14 22:08:31.088+00	1	13
10	1	4	16.00	0.00	20.00	\N	\N	\N	\N	DISPONIBLE	2026-07-09 01:31:43.04+00	\N	13
1	1	1	12.00	0.00	80.00	INI-2026-01	\N	\N	EPP-01	DISPONIBLE	2026-07-09 04:29:24.278846+00	1	13
\.


--
-- Data for Name: movimientos_inventario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movimientos_inventario (id_movimiento, numero_movimiento, fecha_movimiento, tipo_movimiento, id_insumo, id_almacen_origen, id_almacen_destino, cantidad, costo_unitario, motivo, documento_respaldo, usuario_responsable, observaciones, fecha_creacion, id_despacho, id_recepcion, codigo_referencia) FROM stdin;
1	MOV-INI-001	2026-07-04 13:59:53.677794+00	AJUSTE_POSITIVO	1	\N	1	30.00	80.00	Carga inicial de inventario	\N	1	Dato inicial de prueba.	2026-07-04 13:59:53.677794+00	\N	\N	\N
2	MOV-INI-002	2026-07-04 13:59:53.677794+00	AJUSTE_POSITIVO	2	\N	1	50.00	22.00	Carga inicial de inventario	\N	1	Dato inicial de prueba.	2026-07-04 13:59:53.677794+00	\N	\N	\N
3	MOV-INI-003	2026-07-04 13:59:53.677794+00	AJUSTE_POSITIVO	3	\N	1	80.00	36.00	Carga inicial de inventario	\N	1	Dato inicial de prueba.	2026-07-04 13:59:53.677794+00	\N	\N	\N
4	MOV-INI-004	2026-07-04 13:59:53.677794+00	AJUSTE_POSITIVO	4	\N	1	5.00	140.00	Carga inicial de inventario	\N	1	Dato inicial de prueba.	2026-07-04 13:59:53.677794+00	\N	\N	\N
5	MOV-INI-005	2026-07-04 13:59:53.677794+00	AJUSTE_POSITIVO	5	\N	3	500.00	6.50	Carga inicial de inventario	\N	1	Dato inicial de prueba.	2026-07-04 13:59:53.677794+00	\N	\N	\N
6	MOV-INI-006	2026-07-04 13:59:53.677794+00	AJUSTE_POSITIVO	6	\N	2	10.00	500.00	Carga inicial de inventario	\N	1	Dato inicial de prueba.	2026-07-04 13:59:53.677794+00	\N	\N	\N
7	MOV-REC-1	2026-07-04 13:59:53.677794+00	ENTRADA_COMPRA	2	\N	1	30.00	22.00	Entrada automática por recepción de compra	REC-2026-0001	2	Movimiento generado automáticamente desde recepción de compra.	2026-07-04 13:59:53.677794+00	\N	\N	\N
8	MOV-REC-2	2026-07-04 13:59:53.677794+00	ENTRADA_COMPRA	4	\N	1	20.00	145.00	Entrada automática por recepción de compra	REC-2026-0002	2	Movimiento generado automáticamente desde recepción de compra.	2026-07-04 13:59:53.677794+00	\N	\N	\N
9	MOV-REC-3	2026-07-04 13:59:53.677794+00	ENTRADA_COMPRA	3	\N	1	50.00	38.00	Entrada automática por recepción de compra	REC-2026-0003	2	Movimiento generado automáticamente desde recepción de compra.	2026-07-04 13:59:53.677794+00	\N	\N	\N
10	MOV-DES-1	2026-07-04 13:59:53.677794+00	SALIDA_DESPACHO	1	1	\N	20.00	80.00	Salida automática por despacho de insumos	DES-2026-0001	2	Movimiento generado automáticamente desde despacho.	2026-07-04 13:59:53.677794+00	\N	\N	\N
11	MOV-DES-2	2026-07-04 13:59:53.677794+00	SALIDA_DESPACHO	2	1	\N	60.00	22.00	Salida automática por despacho de insumos	DES-2026-0001	2	Movimiento generado automáticamente desde despacho.	2026-07-04 13:59:53.677794+00	\N	\N	\N
12	MOV-DES-3	2026-07-04 13:59:53.677794+00	SALIDA_DESPACHO	4	1	\N	15.00	144.00	Salida automática por despacho de insumos	DES-2026-0002	2	Movimiento generado automáticamente desde despacho.	2026-07-04 13:59:53.677794+00	\N	\N	\N
13	MOV-DES-4	2026-07-04 13:59:53.677794+00	SALIDA_DESPACHO	3	1	\N	100.00	36.77	Salida automática por despacho de insumos	DES-2026-0003	2	Movimiento generado automáticamente desde despacho.	2026-07-04 13:59:53.677794+00	\N	\N	\N
14	MOV-AJU-010	2026-07-04 19:21:37.303195+00	AJUSTE_POSITIVO	1	\N	1	5.00	80.00	Ajuste positivo por conteo físico	ACTA-AJUSTE-010	1	Movimiento de prueba desde Swagger.	2026-07-04 19:21:37.303195+00	\N	\N	\N
16	MOV-1783472387574	2026-07-08 00:59:47.67249+00	DEVOLUCION	1	\N	1	2.00	0.00	ajuste fisico de inventario	\N	\N	esta roto y no hay su araña	2026-07-08 00:59:47.67249+00	\N	\N	\N
17	MOV-1783472519837	2026-07-08 01:01:59.933797+00	ENTRADA_COMPRA	1	\N	4	12.00	0.00	compra de insumos al almacen	\N	\N	despacho	2026-07-08 01:01:59.933797+00	\N	\N	\N
18	MOV-1783472581745	2026-07-08 01:03:01.819471+00	SALIDA_DESPACHO	1	1	\N	1.00	0.00	ajuste	\N	\N	ninguna	2026-07-08 01:03:01.819471+00	\N	\N	\N
19	MOV-1783472777849	2026-07-08 01:06:17.90363+00	AJUSTE_POSITIVO	2	\N	1	700.00	0.00	ajuste de inventario	\N	\N	ninguna	2026-07-08 01:06:17.90363+00	\N	\N	\N
24	MOV-DES-10	2026-07-08 04:49:40.909672+00	SALIDA_DESPACHO	2	1	\N	5.00	22.00	Salida automática por despacho de insumos	DES-2026-0004	13	Movimiento generado automáticamente desde despacho.	2026-07-08 04:49:40.909672+00	9	\N	DES-2026-0004
25	MOV-TRF-2026-0001-S	2026-07-08 04:50:58.841908+00	TRANSFERENCIA_SALIDA	1	1	\N	1.00	80.00	seguridad	\N	13	casco de proteccion	2026-07-08 04:50:58.841908+00	\N	\N	TRF-2026-0001
26	MOV-TRF-2026-0001-E	2026-07-08 04:50:58.841908+00	TRANSFERENCIA_ENTRADA	1	\N	2	1.00	80.00	seguridad	\N	13	casco de proteccion	2026-07-08 04:50:58.841908+00	\N	\N	TRF-2026-0001
27	MOV-DES-11	2026-07-08 04:53:20.676855+00	SALIDA_DESPACHO	2	1	\N	1.00	22.00	Salida automática por despacho de insumos	DES-2026-0005	13	Movimiento generado automáticamente desde despacho.	2026-07-08 04:53:20.676855+00	10	\N	DES-2026-0005
28	MOV-DES-12	2026-07-08 17:55:18.004902+00	SALIDA_DESPACHO	1	1	\N	5.00	80.00	Salida automática por despacho de insumos	DES-2026-0006	13	Movimiento generado automáticamente desde despacho.	2026-07-08 17:55:18.004902+00	11	\N	DES-2026-0006
30	MOV-DES-14	2026-07-08 18:10:10.864923+00	SALIDA_DESPACHO	2	1	\N	50.00	22.00	Salida automatica por despacho formal	DES-2026-0007	13	Movimiento generado automaticamente desde despacho.	2026-07-08 18:10:10.864923+00	13	\N	DES-2026-0007
31	MOV-DES-15	2026-07-08 18:23:32.449482+00	SALIDA_DESPACHO	2	1	\N	30.00	22.00	Salida automatica por despacho formal	DES-2026-0008	13	Movimiento generado automaticamente desde despacho.	2026-07-08 18:23:32.449482+00	14	\N	DES-2026-0008
32	MOV-DES-16	2026-07-09 01:13:10.099049+00	SALIDA_DESPACHO	5	3	\N	8.00	6.50	Salida automatica por despacho formal	DES-2026-0009	13	Movimiento generado automaticamente desde despacho.	2026-07-09 01:13:10.099049+00	15	\N	DES-2026-0009
33	MOV-DES-17	2026-07-09 01:15:14.238231+00	SALIDA_DESPACHO	5	3	\N	2.00	6.50	Salida automatica por despacho formal	DES-2026-0010	13	Movimiento generado automaticamente desde despacho.	2026-07-09 01:15:14.238231+00	16	\N	DES-2026-0010
34	MOV-AJU-1783560639924	2026-07-09 01:30:39.924806+00	AJUSTE_POSITIVO	1	\N	1	7.00	80.00	se encontro varios cascos sin registrar en almacen	\N	13	mas atentos al momento de registrar las compras solicitadas	2026-07-09 01:30:39.924806+00	\N	\N	AJUSTE MANUAL
35	MOV-TRF-2026-0002-S	2026-07-09 01:31:43.029698+00	TRANSFERENCIA_SALIDA	1	1	\N	4.00	80.00	conteo de inventario	\N	13	se presto algo sin registrar	2026-07-09 01:31:43.029698+00	\N	\N	TRF-2026-0002
36	MOV-TRF-2026-0002-E	2026-07-09 01:31:43.029698+00	TRANSFERENCIA_ENTRADA	1	\N	4	4.00	80.00	conteo de inventario	\N	13	se presto algo sin registrar	2026-07-09 01:31:43.029698+00	\N	\N	TRF-2026-0002
37	MOV-DEV-2026-0001	2026-07-09 01:32:53.887556+00	DEVOLUCION	1	\N	1	1.00	80.00	esta en mal estado	DES-2026-0010	13	mas revision al momento de comprar	2026-07-09 01:32:53.887556+00	16	\N	DEV-2026-0001
38	MOV-DES-18	2026-07-09 04:29:24.278846+00	SALIDA_DESPACHO	1	1	\N	2.00	80.00	Salida automatica por despacho formal	DES-2026-0011	13	Movimiento generado automaticamente desde despacho.	2026-07-09 04:29:24.278846+00	17	\N	DES-2026-0011
39	MOV-DES-19	2026-07-09 04:30:54.0753+00	SALIDA_DESPACHO	2	1	\N	67.00	22.00	Salida automatica por despacho formal	DES-2026-0012	13	Movimiento generado automaticamente desde despacho.	2026-07-09 04:30:54.0753+00	18	\N	DES-2026-0012
40	MOV-AJU-1783572060935	2026-07-09 04:41:00.95+00	AJUSTE_NEGATIVO	2	1	\N	2.00	22.00	por mal registro de inventario	\N	13	mas seguro al momento de comprar	2026-07-09 04:41:00.936235+00	\N	\N	AJUSTE MANUAL
41	MOV-REC-4	2026-07-09 06:07:51.443949+00	ENTRADA_COMPRA	9	\N	1	12.00	80.00	Entrada automática por recepción de compra	REC-20260709-271389	13	Movimiento generado automáticamente desde recepción de compra.	2026-07-09 06:07:51.443949+00	\N	4	REC-20260709-271389
42	MOV-REC-5	2026-07-09 14:49:00.193686+00	ENTRADA_COMPRA	9	\N	2	12.00	80.00	Entrada automática por recepción de compra	REC-20260709-540133	13	Movimiento generado automáticamente desde recepción de compra.	2026-07-09 14:49:00.193686+00	\N	5	REC-20260709-540133
43	MOV-DES-20	2026-07-09 15:07:19.963286+00	SALIDA_DESPACHO	9	1	\N	12.00	80.00	Salida automatica por despacho formal	DES-2026-0013	13	Movimiento generado automaticamente desde despacho.	2026-07-09 15:07:19.963286+00	19	\N	DES-2026-0013
\.


--
-- Data for Name: notificaciones; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notificaciones (id_notificacion, tipo_notificacion, titulo, mensaje, id_usuario_destinatario, modulo_relacionado, id_registro_relacionado, prioridad, estado_notificacion, fecha_creacion, fecha_lectura, usuario_genera) FROM stdin;
1	PEDIDO_APROBADO	Pedido aprobado	El pedido PED-2026-0001 fue aprobado para atención.	3	Pedidos	1	ALTA	LEIDA	2026-07-04 13:59:53.677794+00	2026-07-07 01:50:29.331+00	3
3	DESPACHO_REALIZADO	Despacho realizado	El despacho DES-2026-0003 fue entregado completamente.	5	Despachos	3	MEDIA	LEIDA	2026-07-04 13:59:53.677794+00	2026-07-07 01:50:37.612+00	2
6	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260708-369010.	13	Pedidos	6	URGENTE	LEIDA	2026-07-08 01:16:09.119385+00	2026-07-07 21:31:51.984+00	13
7	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260708-054590.	13	Pedidos	7	MEDIA	LEIDA	2026-07-08 02:34:14.67327+00	2026-07-07 23:43:47.711+00	13
16	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0008.	13	Inventario y Despachos	14	MEDIA	LEIDA	2026-07-08 18:23:32.670045+00	2026-07-08 14:24:00.057+00	13
15	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0007.	13	Inventario y Despachos	13	MEDIA	LEIDA	2026-07-08 18:10:11.03723+00	2026-07-08 14:24:20.615+00	13
34	COMPRA_RECIBIDA_COMPLETA	Recepcion de compra registrada	Se registro la recepcion REC-20260709-271389.	13	Compras y Comprobantes	4	MEDIA	LEIDA	2026-07-09 06:07:51.4975+00	2026-07-09 06:11:08.385+00	13
22	PEDIDO_EN_COMPRA	Pedido enviado a compras	El pedido PED-20260708-423244 fue aprobado y enviado a compras por stock insuficiente.	13	Pedidos	15	ALTA	LEIDA	2026-07-08 23:32:31.392725+00	2026-07-09 00:42:18.736+00	13
8	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0004.	13	Inventario y Despachos	9	MEDIA	LEIDA	2026-07-08 04:49:41.023604+00	2026-07-09 01:06:53.8+00	13
10	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0005.	13	Inventario y Despachos	10	MEDIA	LEIDA	2026-07-08 04:53:20.815594+00	2026-07-09 01:06:53.8+00	13
11	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260708-986116.	13	Pedidos	8	MEDIA	LEIDA	2026-07-08 05:03:06.399203+00	2026-07-09 01:06:53.8+00	13
12	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260708-164915.	13	Pedidos	10	MEDIA	LEIDA	2026-07-08 17:52:45.064096+00	2026-07-09 01:06:53.8+00	13
13	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0006.	13	Inventario y Despachos	11	MEDIA	LEIDA	2026-07-08 17:55:18.160258+00	2026-07-09 01:06:53.8+00	13
14	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260708-122030.	13	Pedidos	12	URGENTE	LEIDA	2026-07-08 18:08:42.189192+00	2026-07-09 01:06:53.8+00	13
17	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260708-450595.	13	Pedidos	13	MEDIA	LEIDA	2026-07-08 19:04:10.726786+00	2026-07-09 01:06:53.8+00	13
18	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260708-053270.	13	Pedidos	14	MEDIA	LEIDA	2026-07-08 19:14:13.490103+00	2026-07-09 01:06:53.8+00	13
19	PEDIDO_EN_COMPRA	Pedido enviado a compras	El pedido PED-20260708-053270 fue aprobado y enviado a compras por stock insuficiente.	13	Pedidos	14	ALTA	LEIDA	2026-07-08 23:25:39.599117+00	2026-07-09 01:06:53.8+00	13
20	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260708-423244.	13	Pedidos	15	URGENTE	LEIDA	2026-07-08 23:30:23.451331+00	2026-07-09 01:06:53.8+00	13
21	PEDIDO_OBSERVADO	Pedido observado	El pedido PED-20260708-423244 fue observado: no se especifica bien que uso se dara	13	Pedidos	15	MEDIA	LEIDA	2026-07-08 23:31:05.999012+00	2026-07-09 01:06:53.8+00	13
23	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-20260709-595518.	13	Pedidos	16	MEDIA	LEIDA	2026-07-09 00:39:55.836311+00	2026-07-09 01:06:53.8+00	13
35	COMPRA_RECIBIDA_COMPLETA	Recepcion de compra registrada	Se registro la recepcion REC-20260709-540133.	13	Compras y Comprobantes	5	MEDIA	LEIDA	2026-07-09 14:49:00.25243+00	2026-07-09 15:04:13.469+00	13
36	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0013.	13	Inventario y Despachos	19	MEDIA	LEIDA	2026-07-09 15:07:20.139958+00	2026-07-09 15:08:03.823+00	13
24	PEDIDO_OBSERVADO	Pedido observado	El pedido PED-20260709-595518 fue observado: no se especifica bien porque	13	Pedidos	16	MEDIA	LEIDA	2026-07-09 01:10:37.49904+00	2026-07-09 15:36:26.391+00	13
25	PEDIDO_APROBADO	Pedido aprobado	El pedido PED-20260709-595518 fue aprobado y tiene stock reservado.	13	Pedidos	16	MEDIA	LEIDA	2026-07-09 01:12:05.631399+00	2026-07-09 15:36:26.391+00	13
26	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0009.	13	Inventario y Despachos	15	MEDIA	LEIDA	2026-07-09 01:13:10.212498+00	2026-07-09 15:36:26.391+00	13
31	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0011.	13	Inventario y Despachos	17	MEDIA	LEIDA	2026-07-09 04:29:24.443896+00	2026-07-09 15:36:26.391+00	13
37	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-0001/2026.	13	Pedidos	17	MEDIA	LEIDA	2026-07-14 22:04:36.956087+00	2026-07-15 01:54:14.045+00	13
\.


--
-- Data for Name: orden_compra_detalles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.orden_compra_detalles (id_orden_detalle, id_orden_compra, id_insumo, cantidad_solicitada, cantidad_comprada, precio_unitario, observacion) FROM stdin;
1	1	2	30.00	30.00	22.00	Reposición de guantes.
2	2	4	20.00	20.00	145.00	Compra de brocas.
3	3	3	50.00	50.00	38.00	Compra de aceite lubricante.
11	11	9	12.00	12.00	80.00	color blanco
12	12	9	12.00	12.00	80.00	color blanco
\.


--
-- Data for Name: ordenes_compra; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ordenes_compra (id_orden_compra, numero_orden, codigo_correlativo, id_pedido, id_proveedor, fecha_emision, fecha_estimada_entrega, condicion_pago, forma_pago, moneda, estado_pago, subtotal, descuento, impuesto, estado_compra, observaciones, usuario_genera, fecha_creacion, fecha_actualizacion) FROM stdin;
2	OC-2026-0002	OC-0002-2026	2	1	2026-07-04	2026-07-06	Crédito a 30 días	Transferencia bancaria	BOB	PENDIENTE	2900.00	0.00	0.00	RECIBIDA_COMPLETA	Compra de brocas para perforación.	4	2026-07-04 13:59:53.677794+00	\N
3	OC-2026-0003	OC-0003-2026	3	2	2026-07-04	2026-07-06	Contado	Transferencia bancaria	BOB	PAGADO_COMPLETO	1900.00	0.00	0.00	RECIBIDA_COMPLETA	Compra de aceite para mantenimiento.	4	2026-07-04 13:59:53.677794+00	\N
1	OC-2026-0001	OC-0001-2026	1	1	2026-07-04	2026-07-19	Contado	Transferencia bancaria	BOB	PAGADO_PARCIAL	660.00	20.00	13.00	EN_PROCESO	Orden actualizada.	4	2026-07-04 13:59:53.677794+00	2026-07-04 15:45:43.406+00
11	OC-20260709-126838	CORR-OC-20260709-126838	15	1	2026-07-09	2026-07-08	CONTADO	CHEQUE	BOB	PENDIENTE	960.00	10.00	0.00	RECIBIDA_COMPLETA	ninguna	13	2026-07-09 06:05:26.901689+00	2026-07-09 06:07:51.464+00
12	OC-20260709-377821	CORR-OC-20260709-377821	15	1	2026-07-09	2026-07-09	CONTADO	TRANSFERENCIA	BOB	PENDIENTE	960.00	5.00	0.50	RECIBIDA_COMPLETA	se está realizando la compra para reponer stock del inventario	13	2026-07-09 14:46:17.877961+00	2026-07-09 14:49:00.217+00
\.


--
-- Data for Name: pedido_detalles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pedido_detalles (id_pedido_detalle, id_pedido, id_insumo, cantidad_solicitada, cantidad_aprobada, cantidad_despachada, observacion) FROM stdin;
1	1	1	20.00	20.00	20.00	Cascos para personal operativo.
2	1	2	60.00	60.00	60.00	Guantes para operación mina.
3	2	4	15.00	15.00	15.00	Brocas para perforación.
4	3	3	100.00	100.00	100.00	Aceite para mantenimiento preventivo.
5	4	8	5.00	0.00	0.00	ninguna
6	5	8	4.00	0.00	0.00	color azul
8	7	2	5.00	5.00	5.00	ninguna
7	6	2	2.00	2.00	1.00	ninguna
11	10	1	5.00	5.00	5.00	color blanco
13	12	2	50.00	50.00	50.00	que sea lo mas antes posible
14	13	9	5.00	0.00	0.00	para trabajo de Ingenieros
17	16	5	10.00	10.00	10.00	que sea en galones
15	14	1	1000.00	1000.00	2.00	ninguna
9	8	2	300.00	300.00	97.00	que sea de 1era
16	15	9	12.00	12.00	12.00	color blanco
18	17	2	5.00	5.00	0.00	que sea de una marca especifica de 1ra
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pedidos (id_pedido, numero_pedido, id_usuario_solicitante, id_area_solicitante, fecha_pedido, fecha_requerida, tipo_pedido, prioridad, justificacion, estado_pedido, estado_aprobacion, estado_atencion, id_proveedor_sugerido, archivo_adjunto, centro_costo, turno_guardia, observaciones, id_usuario_revisor, fecha_revision, motivo_rechazo, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por, lugar_uso) FROM stdin;
1	PED-2026-0001	3	1	2026-07-04 17:59:53.677794+00	2026-07-06 04:00:00+00	OPERACION	ALTA	Reposición de EPP para personal de operación mina.	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	CC-MINA-001	Guardia día	Pedido aprobado para despacho y reposición de guantes.	3	2026-07-04 13:59:53.677794+00	\N	2026-07-04 13:59:53.677794+00	2026-07-04 13:59:53.677794+00	3	3	\N
2	PED-2026-0002	3	8	2026-07-04 17:59:53.677794+00	2026-07-07 04:00:00+00	OPERACION	URGENTE	Brocas requeridas para trabajos de perforación programados.	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	CC-PER-001	Guardia noche	Pedido requiere compra por stock insuficiente.	3	2026-07-04 13:59:53.677794+00	\N	2026-07-04 13:59:53.677794+00	2026-07-04 13:59:53.677794+00	3	3	\N
3	PED-2026-0003	5	2	2026-07-04 17:59:53.677794+00	2026-07-08 04:00:00+00	MANTENIMIENTO	MEDIA	Aceite requerido para mantenimiento preventivo de equipos.	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	CC-MANT-001	Guardia día	Pedido requiere compra de reposición.	3	2026-07-04 13:59:53.677794+00	\N	2026-07-04 13:59:53.677794+00	2026-07-04 13:59:53.677794+00	5	3	\N
4	PED-20260707-998843	13	6	2026-07-07 23:36:38.927674+00	2026-07-06 04:00:00+00	NORMAL	MEDIA	material de perforacion	RECHAZADO	RECHAZADO	SIN_ATENDER	\N	\N	\N	\N	se requiere una broca punta diamante, para un barreno de 1.20 metros	13	2026-07-07 15:38:11.051+00	hay s	2026-07-07 19:36:38.927674+00	2026-07-07 15:38:11.051+00	13	\N	\N
5	PED-20260707-624414	13	6	2026-07-08 00:37:04.485217+00	2026-07-06 04:00:00+00	URGENTE	BAJA	federico	RECHAZADO	RECHAZADO	SIN_ATENDER	\N	\N	\N	\N	weretbrnthbg	13	2026-07-07 16:37:25.106+00	nose	2026-07-07 20:37:04.485217+00	2026-07-07 16:37:25.106+00	13	\N	\N
7	PED-20260708-054590	13	6	2026-07-08 06:34:14.640514+00	2026-07-06 04:00:00+00	URGENTE	BAJA	entrega	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	\N	\N	trabajo completado	13	2026-07-07 22:34:48.884+00	\N	2026-07-08 02:34:14.640514+00	2026-07-08 00:49:40.966+00	13	13	\N
6	PED-20260708-369010	13	6	2026-07-08 05:16:09.074032+00	2026-07-03 04:00:00+00	EMERGENCIA	URGENTE	guantes de agua	ENTREGADO_PARCIAL	APROBADO	ATENDIDO_PARCIAL	\N	\N	\N	\N	perfecto	13	2026-07-07 21:16:23.357+00	\N	2026-07-08 01:16:09.074032+00	2026-07-08 00:53:20.764+00	13	13	\N
10	PED-20260708-164915	13	6	2026-07-08 21:52:44.976248+00	2026-07-07 04:00:00+00	URGENTE	MEDIA	para trabajo de operación mina	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	\N	\N	se aprobó porque hay suficiente insumo 	13	2026-07-08 13:53:36.462+00	\N	2026-07-08 17:52:44.976248+00	2026-07-08 13:55:18.11+00	13	13	\N
12	PED-20260708-122030	13	6	2026-07-08 22:08:42.097118+00	2026-07-07 04:00:00+00	EMERGENCIA	URGENTE	guantes de cuero	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	\N	\N	se aprobo por cojudo	13	2026-07-08 14:09:07.495+00	\N	2026-07-08 18:08:42.097118+00	2026-07-08 14:10:10.976+00	13	13	\N
13	PED-20260708-450595	13	6	2026-07-08 23:04:10.648166+00	2026-07-25 04:00:00+00	URGENTE	MEDIA	ningua	CANCELADO	RECHAZADO	SIN_ATENDER	\N	\N	\N	\N	moded	\N	\N	\N	2026-07-08 19:04:10.648166+00	2026-07-08 15:04:28.446+00	13	13	\N
16	PED-20260709-595518	13	6	2026-07-09 00:39:55.656336+00	2026-07-09 12:00:00+00	URGENTE	BAJA	una orquesta	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	mina	dia	\N	13	2026-07-09 01:12:05.554+00	no se especifica bien porque	2026-07-09 00:39:55.656336+00	2026-07-09 01:15:14.317+00	13	13	taller
14	PED-20260708-053270	13	6	2026-07-08 23:14:13.422624+00	2026-07-05 04:00:00+00	URGENTE	MEDIA	de recepcion	ENTREGADO_PARCIAL	APROBADO	ATENDIDO_PARCIAL	\N	\N	aria de soldadura	turno manaña	se realizara una compra	13	2026-07-08 19:25:39.473+00	\N	2026-07-08 19:14:13.422624+00	2026-07-09 04:29:24.383+00	13	13	planta 1 ingenio
8	PED-20260708-986116	13	6	2026-07-08 09:03:06.226546+00	2026-07-07 04:00:00+00	EMERGENCIA	ALTA	operacion	ENTREGADO_PARCIAL	APROBADO	ATENDIDO_PARCIAL	\N	\N	\N	\N	se aprueba por que se necesita para operadores 	13	2026-07-08 01:03:45.158+00	\N	2026-07-08 05:03:06.226546+00	2026-07-09 04:30:54.174+00	13	13	\N
15	PED-20260708-423244	13	6	2026-07-09 03:30:23.336535+00	2026-07-09 04:00:00+00	NORMAL	URGENTE	para trabajo de reparaciones de planta 1, chillar	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	ingenio	1 punta de 8am	se aprueba por que se trabajara con todo el personal correspondiente	13	2026-07-08 19:32:31.278+00	no se especifica bien que uso se dara	2026-07-08 23:30:23.336535+00	2026-07-09 15:07:20.083+00	13	13	planta 1
17	PED-0001/2026	13	6	2026-07-14 22:04:36.843+00	2026-07-18 12:00:00+00	NORMAL	BAJA	Mantenimiento programado	EN_DESPACHO	APROBADO	EN_PROCESO	\N	\N	\N	\N	se prueba por que se hara mantenimiento de molino 3 	13	2026-07-14 22:08:31.072+00	\N	2026-07-14 22:04:36.84335+00	2026-07-14 22:08:54.965+00	13	13	para planta 1 de ingenio
\.


--
-- Data for Name: permisos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permisos (id_permiso, codigo_permiso, modulo, descripcion, fecha_creacion) FROM stdin;
1	DASHBOARD_VER	Dashboard	Ver indicadores del dashboard.	2026-07-04 13:59:53.677794+00
2	ALMACENES_GESTIONAR	Almacenes	Crear, editar y consultar almacenes.	2026-07-04 13:59:53.677794+00
3	PROVEEDORES_GESTIONAR	Proveedores	Crear, editar y consultar proveedores.	2026-07-04 13:59:53.677794+00
4	INSUMOS_GESTIONAR	Insumos	Crear, editar y consultar insumos.	2026-07-04 13:59:53.677794+00
5	INVENTARIO_VER	Inventario	Consultar stock actual.	2026-07-04 13:59:53.677794+00
6	INVENTARIO_MOVIMIENTOS	Inventario	Registrar movimientos de inventario.	2026-07-04 13:59:53.677794+00
7	INVENTARIO_AJUSTES	Inventario	Registrar ajustes de inventario.	2026-07-04 13:59:53.677794+00
8	PEDIDOS_CREAR	Pedidos	Crear pedidos de insumos.	2026-07-04 13:59:53.677794+00
9	PEDIDOS_REVISAR	Pedidos	Revisar pedidos.	2026-07-04 13:59:53.677794+00
10	PEDIDOS_APROBAR	Pedidos	Aprobar o rechazar pedidos.	2026-07-04 13:59:53.677794+00
11	COMPRAS_GESTIONAR	Compras	Gestionar órdenes de compra.	2026-07-04 13:59:53.677794+00
12	RECEPCIONES_REGISTRAR	Compras	Registrar recepción de compras.	2026-07-04 13:59:53.677794+00
13	COMPROBANTES_REGISTRAR	Compras	Registrar comprobantes de compra.	2026-07-04 13:59:53.677794+00
14	DESPACHOS_REALIZAR	Inventario	Realizar despachos de insumos.	2026-07-04 13:59:53.677794+00
15	REPORTES_VER	Reportes	Ver reportes.	2026-07-04 13:59:53.677794+00
16	REPORTES_EXPORTAR	Reportes	Exportar reportes a PDF o Excel.	2026-07-04 13:59:53.677794+00
17	AUDITORIA_VER	Auditoría	Consultar auditoría del sistema.	2026-07-04 13:59:53.677794+00
18	USUARIOS_GESTIONAR	Usuarios	Gestionar usuarios.	2026-07-04 13:59:53.677794+00
19	ROLES_GESTIONAR	Usuarios	Gestionar roles y permisos.	2026-07-04 13:59:53.677794+00
20	NOTIFICACIONES_VER	Notificaciones	Ver notificaciones internas.	2026-07-04 13:59:53.677794+00
\.


--
-- Data for Name: politicas_stock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.politicas_stock (id_politica_stock, id_insumo, id_almacen, stock_minimo, stock_maximo, stock_seguridad, estado, fecha_creacion, creado_por) FROM stdin;
1	1	1	10.00	100.00	15.00	ACTIVO	2026-07-04 13:59:53.677794+00	1
2	2	1	20.00	200.00	30.00	ACTIVO	2026-07-04 13:59:53.677794+00	1
3	3	1	30.00	300.00	50.00	ACTIVO	2026-07-04 13:59:53.677794+00	1
4	4	1	5.00	80.00	10.00	ACTIVO	2026-07-04 13:59:53.677794+00	1
5	5	3	300.00	3000.00	500.00	ACTIVO	2026-07-04 13:59:53.677794+00	1
6	6	2	5.00	80.00	10.00	ACTIVO	2026-07-04 13:59:53.677794+00	1
\.


--
-- Data for Name: proveedor_insumo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.proveedor_insumo (id_proveedor, id_insumo, precio_referencial, tiempo_entrega_dias, estado) FROM stdin;
1	1	85.00	3	ACTIVO
1	2	25.00	3	ACTIVO
1	4	145.00	5	ACTIVO
2	3	38.00	2	ACTIVO
2	5	6.80	2	ACTIVO
3	6	520.00	7	ACTIVO
\.


--
-- Data for Name: proveedores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.proveedores (id_proveedor, codigo_proveedor, razon_social, nombre_comercial, nit, rubro, tipo_insumos_provee, persona_contacto, cargo_contacto, telefono, celular_whatsapp, correo, direccion, ciudad, condiciones_pago, forma_pago, tiempo_estimado_entrega, calificacion, documentacion_vigente, estado, observaciones, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
2	PROV-002	Lubricantes y Combustibles Oruro S.A.	LubriOruro	1001001002	Lubricantes y combustible	Aceites, lubricantes y combustible	Patricia Rojas	Responsable de ventas	25250002	72000002	contacto@lubrioruro.local	Zona industrial norte	Oruro	Contado o crédito a 15 días	Transferencia bancaria	2 a 4 días hábiles	4.60	t	ACTIVO	Proveedor de lubricantes y combustible.	2026-07-04 13:59:53.677794+00	\N	1	\N
3	PROV-003	Materiales Controlados Mina S.R.L.	MCM Controlados	1001001003	Material controlado	Material explosivo controlado y accesorios autorizados	Eduardo Lima	Encargado de operaciones	25250003	72000003	operaciones@mcmcontrolados.local	Zona autorizada de almacenamiento	Oruro	Según contrato y autorización	Transferencia bancaria	Según autorización y programación	4.50	t	ACTIVO	Proveedor sujeto a control documental.	2026-07-04 13:59:53.677794+00	2026-07-08 13:18:01.447+00	1	\N
5	PROV-22	INGRESO DE INSUMOS DE COMBUSTIBLE (GASOLINA, DIESEL)	YPFB VINTO	1234567	COMBUSTIBLE	COMBUSTIBLE DE TRANSPORTE	FEDERICO CHOQUECALLATA VILLCA	\N	74477014	74477014	feyckon@gmail.com	\N	Pando	\N	\N	\N	\N	t	ELIMINADO	\N	2026-07-07 19:30:42.568173+00	2026-07-07 20:51:43.059+00	\N	\N
4	PROV-004	Ferretería Industrial Oruro S.R.L.	FerroMin Oruro	1020304050	HERRAMIENTAS_REPUESTOS	Herramientas manuales, repuestos y equipos menores	Carlos Rojas	Ejecutivo comercial	252099999	70000999	ventas@ferromin.com	Av. Circunvalación, zona norte, Oruro	Tarija	Crédito a 30 días	Transferencia bancaria	48 horas	4.80	t	ACTIVO	Proveedor actualizado con mejor calificación por cumplimiento.	2026-07-04 19:02:36.612687+00	2026-07-14 23:16:50.855+00	\N	\N
1	PROV-001	Suministros Andinos S.R.L.	Suministros Andinos	1001001001	HERRAMIENTAS_REPUESTOS	Herramientas, EPP, repuestos y material de perforación	Roberto Salazar	Ejecutivo comercial	25250001	72000021	ventas@suministrosandinos.local	Av. Industrial Nro. 120	Oruro	Crédito a 30 días	Transferencia bancaria	3 a 5 días hábiles	4.80	t	ACTIVO	Proveedor principal de herramientas y seguridad.	2026-07-04 13:59:53.677794+00	2026-07-15 18:34:56.614+00	1	\N
\.


--
-- Data for Name: recepcion_detalles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recepcion_detalles (id_recepcion_detalle, id_recepcion, id_orden_detalle, id_insumo, cantidad_comprada, cantidad_recibida, cantidad_aceptada, cantidad_rechazada, cantidad_faltante, motivo_rechazo, estado_conformidad, observaciones) FROM stdin;
1	1	1	2	30.00	30.00	30.00	0.00	0.00	\N	CONFORME	Cantidad recibida conforme.
2	2	2	4	20.00	20.00	20.00	0.00	0.00	\N	CONFORME	Cantidad recibida conforme.
3	3	3	3	50.00	50.00	50.00	0.00	0.00	\N	CONFORME	Cantidad recibida conforme.
4	4	11	9	12.00	12.00	12.00	0.00	0.00	\N	CONFORME	llego muy tarde para la proxima llegue temprano
5	5	12	9	12.00	12.00	12.00	0.00	0.00	\N	CONFORME	esta perfecto
\.


--
-- Data for Name: recepciones_compra; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recepciones_compra (id_recepcion, numero_recepcion, id_orden_compra, id_proveedor, id_almacen_destino, fecha_estimada_recepcion, fecha_real_recepcion, id_responsable_recepcion, estado_recepcion, documento_respaldo, observaciones, fecha_creacion) FROM stdin;
1	REC-2026-0001	1	1	1	2026-07-05	2026-07-05	2	RECIBIDA_COMPLETA	recepcion_guantes_0001.pdf	Recepción conforme.	2026-07-04 13:59:53.677794+00
2	REC-2026-0002	2	1	1	2026-07-06	2026-07-06	2	RECIBIDA_COMPLETA	recepcion_brocas_0002.pdf	Recepción conforme.	2026-07-04 13:59:53.677794+00
3	REC-2026-0003	3	2	1	2026-07-06	2026-07-06	2	RECIBIDA_COMPLETA	recepcion_aceite_0003.pdf	Recepción conforme.	2026-07-04 13:59:53.677794+00
4	REC-20260709-271389	11	1	1	\N	2026-07-09	13	RECIBIDA_COMPLETA	gr-3	trado mucho	2026-07-09 06:07:51.443949+00
5	REC-20260709-540133	12	1	2	\N	2026-07-09	13	RECIBIDA_COMPLETA	ninguno	esta perfecto en el insumo pedido	2026-07-09 14:49:00.193686+00
\.


--
-- Data for Name: reservas_stock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservas_stock (id_reserva_stock, id_inventario, id_insumo, id_almacen, id_pedido, id_pedido_detalle, cantidad_reservada, estado, fecha_reserva, fecha_liberacion) FROM stdin;
2	2	2	1	6	7	1.00	ACTIVA	2026-07-08 17:49:43.236388+00	\N
4	1	1	1	10	11	0.00	LIBERADA	2026-07-08 17:53:36.445065+00	2026-07-08 18:04:11.273564+00
6	2	2	1	12	13	0.00	LIBERADA	2026-07-08 18:09:07.478365+00	2026-07-08 14:10:10.972+00
7	5	5	3	16	17	0.00	LIBERADA	2026-07-09 01:12:05.55203+00	2026-07-09 01:15:14.315+00
3	2	2	1	8	9	203.00	ACTIVA	2026-07-08 17:49:43.236388+00	\N
8	2	2	1	17	18	5.00	ACTIVA	2026-07-14 22:08:31.063171+00	\N
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles (id_rol, nombre_rol, descripcion, estado, fecha_creacion, fecha_actualizacion) FROM stdin;
3	Encargado de almacén	Responsable operativo de almacenes, inventario, movimientos y despachos.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-15 20:21:01.065+00
4	Supervisor de mina	Solicita insumos para operación minera y realiza seguimiento a pedidos.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-15 20:21:01.07+00
14	Jefe de área	Responsable de revisar, aprobar, observar o rechazar pedidos del área.	ACTIVO	2026-07-15 00:21:54.101865+00	2026-07-15 20:21:01.073+00
5	Encargado de compras	Responsable de proveedores, compras, recepciones y comprobantes.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-15 20:21:01.077+00
6	Auditor	Usuario con acceso de consulta a auditoría, trazabilidad y reportes.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-15 20:21:01.081+00
7	Usuario solicitante	Usuario que crea pedidos de insumos y realiza seguimiento a sus solicitudes.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-15 20:21:01.084+00
2	Jefe de almacén	Responsable de almacenes, inventario y despachos.	INACTIVO	2026-07-04 13:59:53.677794+00	2026-07-06 20:33:11.428352+00
1	Administrador del sistema	Acceso total al sistema, usuarios, seguridad, reportes y auditoria.	ACTIVO	2026-07-04 13:59:53.677794+00	2026-07-15 20:21:01.056+00
\.


--
-- Data for Name: roles_permisos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.roles_permisos (id_rol, id_permiso) FROM stdin;
1	1
1	2
1	3
1	4
1	5
1	6
1	7
1	8
1	9
1	10
1	11
1	12
1	13
1	14
1	15
1	16
1	17
1	18
1	19
1	20
2	1
2	2
2	5
2	6
2	7
2	14
2	15
2	20
3	1
3	5
3	6
3	14
3	20
4	1
4	9
4	10
4	15
4	20
5	1
5	3
5	11
5	12
5	13
5	15
5	20
6	1
6	15
6	17
6	20
7	1
7	8
7	20
\.


--
-- Data for Name: tipos_insumo; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tipos_insumo (id_tipo_insumo, nombre_tipo, descripcion, estado, fecha_creacion, creado_por) FROM stdin;
1	Consumible	Insumo que se consume durante la operación.	ACTIVO	2026-07-04 13:59:53.677794+00	1
2	Herramienta	Herramienta de uso operativo.	ACTIVO	2026-07-04 13:59:53.677794+00	1
3	Repuesto	Repuesto de equipos o maquinaria.	ACTIVO	2026-07-04 13:59:53.677794+00	1
4	Material de seguridad	Insumo relacionado con seguridad industrial.	ACTIVO	2026-07-04 13:59:53.677794+00	1
5	Combustible	Insumo combustible.	ACTIVO	2026-07-04 13:59:53.677794+00	1
6	Material controlado	Insumo que requiere control especial.	ACTIVO	2026-07-04 13:59:53.677794+00	1
\.


--
-- Data for Name: unidades_medida; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.unidades_medida (id_unidad_medida, nombre_unidad, abreviatura, descripcion, estado, fecha_creacion) FROM stdin;
1	Unidad	unid	Unidad individual.	ACTIVO	2026-07-04 13:59:53.677794+00
2	Par	par	Par de elementos.	ACTIVO	2026-07-04 13:59:53.677794+00
3	Litro	L	Medida de volumen en litros.	ACTIVO	2026-07-04 13:59:53.677794+00
4	Kilogramo	kg	Medida de peso en kilogramos.	ACTIVO	2026-07-04 13:59:53.677794+00
5	Caja	caja	Presentación por caja.	ACTIVO	2026-07-04 13:59:53.677794+00
6	Metro	m	Medida de longitud en metros.	ACTIVO	2026-07-04 13:59:53.677794+00
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios (id_usuario, id_area, id_rol, nombre_completo, nombre_usuario, correo, password_hash, telefono, cargo, estado, ultimo_inicio_sesion, intentos_fallidos, cambio_obligatorio, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por, cedula_identidad, complemento_ci, expedido_ci) FROM stdin;
1	6	1	Juan Pérez Administrador	jperez	jperez@mineria.local	$2b$10$IlEfj/NaKtlzqaJxkcOZAeATSfvCdAu402KRTRrGwDh1i5uveLxKG	70000001	Administrador del sistema	ELIMINADO	2026-07-08 17:45:57.870615+00	0	f	2026-07-04 13:59:53.677794+00	2026-07-08 17:45:57.870615+00	\N	\N	\N	\N	\N
15	16	6	maria gutierrez beltran	maria	maria@gmail.com	$2b$10$Zt3mSg1cXqlwRNYpQwzlyedX0WTnXhzbQ//fmGQlJQA2jabG1VeIS	74717475	auditor interno de administracion	ACTIVO	2026-07-14 23:47:34.081+00	0	f	2026-07-07 23:48:55.477258+00	2026-07-14 23:47:34.081+00	\N	\N	12345678	1A	LP
6	6	1	Pedro Mamani Flores	pmamani	pmamani@mineria.local	$2b$10$IlEfj/NaKtlzqaJxkcOZAeATSfvCdAu402KRTRrGwDh1i5uveLxKG	70000006	Administrador del sistema	ELIMINADO	2026-07-06 16:44:08.809+00	0	f	2026-07-05 14:51:45.303927+00	2026-07-07 22:02:12.323829+00	\N	\N	\N	\N	\N
14	16	6	maria gutierrez beltran	maria 	mari@gmail.com	$2b$10$AkCmSeWNkX7yf14XC6/Sp.O7TotEWJCliwZN7Nb5faq00qnEUmd4G	64959285	\N	ELIMINADO	\N	0	f	2026-07-07 22:04:55.661036+00	2026-07-07 23:28:02.610069+00	\N	\N	\N	\N	\N
19	5	3	juvenal choquecallata villca	juve	juve@gmail.com	$2b$10$eHG8Nsg6QbOKUSQvXrG5FuHJOtaO6ziZeVQM9qts7Y8/jo6ImXgby	74477171	\N	ACTIVO	2026-07-15 01:25:24.841+00	0	f	2026-07-14 23:32:16.800623+00	2026-07-15 01:25:24.841+00	\N	\N	23456782	\N	LP
16	4	5	brayan maria mula	brayan 	mula@gmail.com	$2b$10$vuxc6rSoZLWiQnR01Ep9WOHVR7lp20nJ6uCuVcpYMyzW2/wZuUm0S	74845692	\N	ELIMINADO	\N	0	f	2026-07-08 00:00:58.958626+00	2026-07-08 00:01:10.717446+00	\N	\N	\N	\N	\N
4	4	5	Ana Vargas Choque	avargas	avargas@mineria.local	$2b$10$IlEfj/NaKtlzqaJxkcOZAeATSfvCdAu402KRTRrGwDh1i5uveLxKG	70000004	Encargada de compras	ACTIVO	2026-07-15 01:28:09.127+00	0	f	2026-07-04 13:59:53.677794+00	2026-07-15 01:28:09.127+00	\N	\N	12913568	\N	BN
2	5	2	María Condori Alarcón	mcondori	mcondori@mineria.local	$2b$10$IlEfj/NaKtlzqaJxkcOZAeATSfvCdAu402KRTRrGwDh1i5uveLxKG	70000002	Jefe de almacén	ACTIVO	2026-07-15 00:51:38.175+00	0	f	2026-07-04 13:59:53.677794+00	2026-07-15 19:09:43.815+00	\N	\N	1236957	\N	CB
17	8	7	efwrebtryntumyynrtbwecs	wdefevtbryrb	duki@gmail.com	$2b$10$TsbMscd2L52uZN1SkXkdgeO2C9Tkt/W1LjTzqGwzlVT9oZL9R9ZX.	57486814	\N	ELIMINADO	\N	0	f	2026-07-14 18:41:06.462512+00	2026-07-14 18:46:27.853+00	\N	\N	546154815	\N	\N
3	1	4	Carlos Quispe Mamani	cquispe	cquispe@mineria.local	$2b$10$IlEfj/NaKtlzqaJxkcOZAeATSfvCdAu402KRTRrGwDh1i5uveLxKG	70000003	Supervisor de mina	ACTIVO	2026-07-15 01:21:04.272+00	0	f	2026-07-04 13:59:53.677794+00	2026-07-15 02:20:47.796+00	\N	\N	1265896	2A	LP
13	6	1	federico choquecallata villca	federico	feyckon@gmail.com	$2b$10$XW497TI/Gz0j54HkCRhhqO3OoYNe1r3fybHntpDVoIa4HFJkR7Wje	74477014	presidente de Vigilancia	ACTIVO	2026-07-15 20:20:43.84+00	0	f	2026-07-07 19:18:06.201417+00	2026-07-15 20:20:43.84+00	\N	\N	12901305	\N	OR
18	8	7	federico choquecalata zuares	federico1	feyckon1@gmail.com	$2b$10$qxdDxp3seHGUqro4xaK8h.2ott1s2KgoX0ieluwdbFQCjtpfbGOYu	75847584	\N	ELIMINADO	\N	0	f	2026-07-14 21:27:19.84333+00	2026-07-14 21:27:41.854+00	\N	\N	12345675	\N	CB
5	1	7	Luis Mamani Flores	lmamani	lmamani@mineria.local	$2b$10$IlEfj/NaKtlzqaJxkcOZAeATSfvCdAu402KRTRrGwDh1i5uveLxKG	70000005	Técnico de mantenimiento	ACTIVO	2026-07-15 01:32:46.99+00	0	f	2026-07-04 13:59:53.677794+00	2026-07-15 02:40:40.237+00	\N	\N	23456789	\N	LP
\.


--
-- Name: almacenes_id_almacen_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.almacenes_id_almacen_seq', 5, true);


--
-- Name: aprobaciones_pedido_id_aprobacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.aprobaciones_pedido_id_aprobacion_seq', 3, true);


--
-- Name: areas_id_area_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.areas_id_area_seq', 16, true);


--
-- Name: auditorias_id_auditoria_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.auditorias_id_auditoria_seq', 572, true);


--
-- Name: categorias_insumo_id_categoria_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categorias_insumo_id_categoria_seq', 6, true);


--
-- Name: comprobantes_compra_id_comprobante_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comprobantes_compra_id_comprobante_seq', 5, true);


--
-- Name: despacho_detalles_id_despacho_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.despacho_detalles_id_despacho_detalle_seq', 20, true);


--
-- Name: despachos_id_despacho_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.despachos_id_despacho_seq', 19, true);


--
-- Name: insumos_id_insumo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.insumos_id_insumo_seq', 9, true);


--
-- Name: inventarios_id_inventario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inventarios_id_inventario_seq', 13, true);


--
-- Name: movimientos_inventario_id_movimiento_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.movimientos_inventario_id_movimiento_seq', 43, true);


--
-- Name: notificaciones_id_notificacion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notificaciones_id_notificacion_seq', 38, true);


--
-- Name: orden_compra_detalles_id_orden_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.orden_compra_detalles_id_orden_detalle_seq', 12, true);


--
-- Name: ordenes_compra_id_orden_compra_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ordenes_compra_id_orden_compra_seq', 12, true);


--
-- Name: pedido_detalles_id_pedido_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pedido_detalles_id_pedido_detalle_seq', 18, true);


--
-- Name: pedidos_id_pedido_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pedidos_id_pedido_seq', 17, true);


--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.permisos_id_permiso_seq', 20, true);


--
-- Name: politicas_stock_id_politica_stock_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.politicas_stock_id_politica_stock_seq', 6, true);


--
-- Name: proveedores_id_proveedor_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.proveedores_id_proveedor_seq', 5, true);


--
-- Name: recepcion_detalles_id_recepcion_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recepcion_detalles_id_recepcion_detalle_seq', 5, true);


--
-- Name: recepciones_compra_id_recepcion_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recepciones_compra_id_recepcion_seq', 5, true);


--
-- Name: reservas_stock_id_reserva_stock_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reservas_stock_id_reserva_stock_seq', 8, true);


--
-- Name: roles_id_rol_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.roles_id_rol_seq', 14, true);


--
-- Name: tipos_insumo_id_tipo_insumo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tipos_insumo_id_tipo_insumo_seq', 6, true);


--
-- Name: unidades_medida_id_unidad_medida_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.unidades_medida_id_unidad_medida_seq', 6, true);


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_id_usuario_seq', 19, true);


--
-- Name: almacenes almacenes_codigo_almacen_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_codigo_almacen_key UNIQUE (codigo_almacen);


--
-- Name: almacenes almacenes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_pkey PRIMARY KEY (id_almacen);


--
-- Name: aprobaciones_pedido aprobaciones_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aprobaciones_pedido
    ADD CONSTRAINT aprobaciones_pedido_pkey PRIMARY KEY (id_aprobacion);


--
-- Name: areas areas_nombre_area_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_nombre_area_key UNIQUE (nombre_area);


--
-- Name: areas areas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id_area);


--
-- Name: auditorias auditorias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditorias
    ADD CONSTRAINT auditorias_pkey PRIMARY KEY (id_auditoria);


--
-- Name: categorias_insumo categorias_insumo_nombre_categoria_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias_insumo
    ADD CONSTRAINT categorias_insumo_nombre_categoria_key UNIQUE (nombre_categoria);


--
-- Name: categorias_insumo categorias_insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias_insumo
    ADD CONSTRAINT categorias_insumo_pkey PRIMARY KEY (id_categoria);


--
-- Name: comprobantes_compra comprobantes_compra_numero_comprobante_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_numero_comprobante_key UNIQUE (numero_comprobante);


--
-- Name: comprobantes_compra comprobantes_compra_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_pkey PRIMARY KEY (id_comprobante);


--
-- Name: despacho_detalles despacho_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despacho_detalles
    ADD CONSTRAINT despacho_detalles_pkey PRIMARY KEY (id_despacho_detalle);


--
-- Name: despachos despachos_numero_despacho_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_numero_despacho_key UNIQUE (numero_despacho);


--
-- Name: despachos despachos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_pkey PRIMARY KEY (id_despacho);


--
-- Name: insumos insumos_codigo_barra_qr_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_codigo_barra_qr_key UNIQUE (codigo_barra_qr);


--
-- Name: insumos insumos_codigo_interno_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_codigo_interno_key UNIQUE (codigo_interno);


--
-- Name: insumos insumos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_pkey PRIMARY KEY (id_insumo);


--
-- Name: inventarios inventarios_id_insumo_id_almacen_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_insumo_id_almacen_key UNIQUE (id_insumo, id_almacen);


--
-- Name: inventarios inventarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_pkey PRIMARY KEY (id_inventario);


--
-- Name: movimientos_inventario movimientos_inventario_numero_movimiento_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_numero_movimiento_key UNIQUE (numero_movimiento);


--
-- Name: movimientos_inventario movimientos_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_pkey PRIMARY KEY (id_movimiento);


--
-- Name: notificaciones notificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id_notificacion);


--
-- Name: orden_compra_detalles orden_compra_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_compra_detalles
    ADD CONSTRAINT orden_compra_detalles_pkey PRIMARY KEY (id_orden_detalle);


--
-- Name: ordenes_compra ordenes_compra_codigo_correlativo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_codigo_correlativo_key UNIQUE (codigo_correlativo);


--
-- Name: ordenes_compra ordenes_compra_numero_orden_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_numero_orden_key UNIQUE (numero_orden);


--
-- Name: ordenes_compra ordenes_compra_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_pkey PRIMARY KEY (id_orden_compra);


--
-- Name: pedido_detalles pedido_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_detalles
    ADD CONSTRAINT pedido_detalles_pkey PRIMARY KEY (id_pedido_detalle);


--
-- Name: pedidos pedidos_numero_pedido_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_numero_pedido_key UNIQUE (numero_pedido);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id_pedido);


--
-- Name: permisos permisos_codigo_permiso_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_codigo_permiso_key UNIQUE (codigo_permiso);


--
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id_permiso);


--
-- Name: politicas_stock politicas_stock_id_insumo_id_almacen_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_id_insumo_id_almacen_key UNIQUE (id_insumo, id_almacen);


--
-- Name: politicas_stock politicas_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_pkey PRIMARY KEY (id_politica_stock);


--
-- Name: proveedor_insumo proveedor_insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor_insumo
    ADD CONSTRAINT proveedor_insumo_pkey PRIMARY KEY (id_proveedor, id_insumo);


--
-- Name: proveedores proveedores_codigo_proveedor_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_codigo_proveedor_key UNIQUE (codigo_proveedor);


--
-- Name: proveedores proveedores_nit_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_nit_key UNIQUE (nit);


--
-- Name: proveedores proveedores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_pkey PRIMARY KEY (id_proveedor);


--
-- Name: recepcion_detalles recepcion_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepcion_detalles
    ADD CONSTRAINT recepcion_detalles_pkey PRIMARY KEY (id_recepcion_detalle);


--
-- Name: recepciones_compra recepciones_compra_numero_recepcion_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_numero_recepcion_key UNIQUE (numero_recepcion);


--
-- Name: recepciones_compra recepciones_compra_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_pkey PRIMARY KEY (id_recepcion);


--
-- Name: reservas_stock reservas_stock_id_pedido_detalle_id_almacen_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_pedido_detalle_id_almacen_key UNIQUE (id_pedido_detalle, id_almacen);


--
-- Name: reservas_stock reservas_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_pkey PRIMARY KEY (id_reserva_stock);


--
-- Name: roles roles_nombre_rol_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_rol_key UNIQUE (nombre_rol);


--
-- Name: roles_permisos roles_permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_pkey PRIMARY KEY (id_rol, id_permiso);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_rol);


--
-- Name: tipos_insumo tipos_insumo_nombre_tipo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_insumo
    ADD CONSTRAINT tipos_insumo_nombre_tipo_key UNIQUE (nombre_tipo);


--
-- Name: tipos_insumo tipos_insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_insumo
    ADD CONSTRAINT tipos_insumo_pkey PRIMARY KEY (id_tipo_insumo);


--
-- Name: unidades_medida unidades_medida_abreviatura_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unidades_medida
    ADD CONSTRAINT unidades_medida_abreviatura_key UNIQUE (abreviatura);


--
-- Name: unidades_medida unidades_medida_nombre_unidad_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unidades_medida
    ADD CONSTRAINT unidades_medida_nombre_unidad_key UNIQUE (nombre_unidad);


--
-- Name: unidades_medida unidades_medida_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.unidades_medida
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id_unidad_medida);


--
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- Name: usuarios usuarios_nombre_usuario_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_nombre_usuario_key UNIQUE (nombre_usuario);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: idx_auditorias_usuario_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_auditorias_usuario_fecha ON public.auditorias USING btree (id_usuario, fecha_hora);


--
-- Name: idx_despachos_pedido; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_despachos_pedido ON public.despachos USING btree (id_pedido);


--
-- Name: idx_insumos_categoria; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_insumos_categoria ON public.insumos USING btree (id_categoria);


--
-- Name: idx_insumos_tipo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_insumos_tipo ON public.insumos USING btree (id_tipo_insumo);


--
-- Name: idx_inventarios_almacen; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inventarios_almacen ON public.inventarios USING btree (id_almacen);


--
-- Name: idx_inventarios_insumo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_inventarios_insumo ON public.inventarios USING btree (id_insumo);


--
-- Name: idx_movimientos_insumo_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_movimientos_insumo_fecha ON public.movimientos_inventario USING btree (id_insumo, fecha_movimiento);


--
-- Name: idx_notificaciones_usuario_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_notificaciones_usuario_estado ON public.notificaciones USING btree (id_usuario_destinatario, estado_notificacion);


--
-- Name: idx_ordenes_proveedor; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ordenes_proveedor ON public.ordenes_compra USING btree (id_proveedor);


--
-- Name: idx_pedidos_area; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_area ON public.pedidos USING btree (id_area_solicitante);


--
-- Name: idx_pedidos_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_estado ON public.pedidos USING btree (estado_pedido);


--
-- Name: idx_reservas_stock_inventario_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservas_stock_inventario_estado ON public.reservas_stock USING btree (id_inventario, estado);


--
-- Name: idx_reservas_stock_pedido_estado; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reservas_stock_pedido_estado ON public.reservas_stock USING btree (id_pedido, estado);


--
-- Name: idx_usuarios_area; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usuarios_area ON public.usuarios USING btree (id_area);


--
-- Name: idx_usuarios_rol; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usuarios_rol ON public.usuarios USING btree (id_rol);


--
-- Name: despacho_detalles trg_despacho_actualiza_inventario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_despacho_actualiza_inventario AFTER INSERT ON public.despacho_detalles FOR EACH ROW EXECUTE FUNCTION public.fn_despacho_actualiza_inventario();


--
-- Name: recepcion_detalles trg_recepcion_actualiza_inventario; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_recepcion_actualiza_inventario AFTER INSERT ON public.recepcion_detalles FOR EACH ROW EXECUTE FUNCTION public.fn_recepcion_actualiza_inventario();


--
-- Name: almacenes almacenes_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: almacenes almacenes_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: almacenes almacenes_id_responsable_principal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_id_responsable_principal_fkey FOREIGN KEY (id_responsable_principal) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: almacenes almacenes_id_responsable_suplente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_id_responsable_suplente_fkey FOREIGN KEY (id_responsable_suplente) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: aprobaciones_pedido aprobaciones_pedido_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aprobaciones_pedido
    ADD CONSTRAINT aprobaciones_pedido_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido) ON DELETE CASCADE;


--
-- Name: aprobaciones_pedido aprobaciones_pedido_id_usuario_aprobador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aprobaciones_pedido
    ADD CONSTRAINT aprobaciones_pedido_id_usuario_aprobador_fkey FOREIGN KEY (id_usuario_aprobador) REFERENCES public.usuarios(id_usuario);


--
-- Name: auditorias auditorias_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.auditorias
    ADD CONSTRAINT auditorias_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: categorias_insumo categorias_insumo_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias_insumo
    ADD CONSTRAINT categorias_insumo_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: comprobantes_compra comprobantes_compra_id_orden_compra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_id_orden_compra_fkey FOREIGN KEY (id_orden_compra) REFERENCES public.ordenes_compra(id_orden_compra);


--
-- Name: comprobantes_compra comprobantes_compra_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor);


--
-- Name: comprobantes_compra comprobantes_compra_usuario_registra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_usuario_registra_fkey FOREIGN KEY (usuario_registra) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: despacho_detalles despacho_detalles_id_despacho_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despacho_detalles
    ADD CONSTRAINT despacho_detalles_id_despacho_fkey FOREIGN KEY (id_despacho) REFERENCES public.despachos(id_despacho) ON DELETE CASCADE;


--
-- Name: despacho_detalles despacho_detalles_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despacho_detalles
    ADD CONSTRAINT despacho_detalles_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: despachos despachos_id_almacen_salida_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_almacen_salida_fkey FOREIGN KEY (id_almacen_salida) REFERENCES public.almacenes(id_almacen);


--
-- Name: despachos despachos_id_area_solicitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_area_solicitante_fkey FOREIGN KEY (id_area_solicitante) REFERENCES public.areas(id_area);


--
-- Name: despachos despachos_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido);


--
-- Name: despachos despachos_id_responsable_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_responsable_almacen_fkey FOREIGN KEY (id_responsable_almacen) REFERENCES public.usuarios(id_usuario);


--
-- Name: despachos despachos_id_usuario_solicitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_usuario_solicitante_fkey FOREIGN KEY (id_usuario_solicitante) REFERENCES public.usuarios(id_usuario);


--
-- Name: despachos despachos_usuario_registra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_usuario_registra_fkey FOREIGN KEY (usuario_registra) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: movimientos_inventario fk_movimientos_inventario_despacho; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT fk_movimientos_inventario_despacho FOREIGN KEY (id_despacho) REFERENCES public.despachos(id_despacho) ON DELETE SET NULL;


--
-- Name: movimientos_inventario fk_movimientos_inventario_recepcion; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT fk_movimientos_inventario_recepcion FOREIGN KEY (id_recepcion) REFERENCES public.recepciones_compra(id_recepcion) ON DELETE SET NULL;


--
-- Name: insumos insumos_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: insumos insumos_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: insumos insumos_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categorias_insumo(id_categoria);


--
-- Name: insumos insumos_id_tipo_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_id_tipo_insumo_fkey FOREIGN KEY (id_tipo_insumo) REFERENCES public.tipos_insumo(id_tipo_insumo);


--
-- Name: insumos insumos_id_unidad_medida_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_id_unidad_medida_fkey FOREIGN KEY (id_unidad_medida) REFERENCES public.unidades_medida(id_unidad_medida);


--
-- Name: insumos insumos_id_unidad_medida_secundaria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_id_unidad_medida_secundaria_fkey FOREIGN KEY (id_unidad_medida_secundaria) REFERENCES public.unidades_medida(id_unidad_medida);


--
-- Name: inventarios inventarios_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: inventarios inventarios_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: inventarios inventarios_id_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_almacen_fkey FOREIGN KEY (id_almacen) REFERENCES public.almacenes(id_almacen);


--
-- Name: inventarios inventarios_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: movimientos_inventario movimientos_inventario_id_almacen_destino_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_almacen_destino_fkey FOREIGN KEY (id_almacen_destino) REFERENCES public.almacenes(id_almacen);


--
-- Name: movimientos_inventario movimientos_inventario_id_almacen_origen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_almacen_origen_fkey FOREIGN KEY (id_almacen_origen) REFERENCES public.almacenes(id_almacen);


--
-- Name: movimientos_inventario movimientos_inventario_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: movimientos_inventario movimientos_inventario_usuario_responsable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_usuario_responsable_fkey FOREIGN KEY (usuario_responsable) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: notificaciones notificaciones_id_usuario_destinatario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_id_usuario_destinatario_fkey FOREIGN KEY (id_usuario_destinatario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;


--
-- Name: notificaciones notificaciones_usuario_genera_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_usuario_genera_fkey FOREIGN KEY (usuario_genera) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: orden_compra_detalles orden_compra_detalles_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_compra_detalles
    ADD CONSTRAINT orden_compra_detalles_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: orden_compra_detalles orden_compra_detalles_id_orden_compra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.orden_compra_detalles
    ADD CONSTRAINT orden_compra_detalles_id_orden_compra_fkey FOREIGN KEY (id_orden_compra) REFERENCES public.ordenes_compra(id_orden_compra) ON DELETE CASCADE;


--
-- Name: ordenes_compra ordenes_compra_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido);


--
-- Name: ordenes_compra ordenes_compra_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor);


--
-- Name: ordenes_compra ordenes_compra_usuario_genera_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_usuario_genera_fkey FOREIGN KEY (usuario_genera) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: pedido_detalles pedido_detalles_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_detalles
    ADD CONSTRAINT pedido_detalles_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: pedido_detalles pedido_detalles_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_detalles
    ADD CONSTRAINT pedido_detalles_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido) ON DELETE CASCADE;


--
-- Name: pedidos pedidos_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: pedidos pedidos_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: pedidos pedidos_id_area_solicitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_area_solicitante_fkey FOREIGN KEY (id_area_solicitante) REFERENCES public.areas(id_area);


--
-- Name: pedidos pedidos_id_proveedor_sugerido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_proveedor_sugerido_fkey FOREIGN KEY (id_proveedor_sugerido) REFERENCES public.proveedores(id_proveedor);


--
-- Name: pedidos pedidos_id_usuario_revisor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_usuario_revisor_fkey FOREIGN KEY (id_usuario_revisor) REFERENCES public.usuarios(id_usuario);


--
-- Name: pedidos pedidos_id_usuario_solicitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_usuario_solicitante_fkey FOREIGN KEY (id_usuario_solicitante) REFERENCES public.usuarios(id_usuario);


--
-- Name: politicas_stock politicas_stock_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: politicas_stock politicas_stock_id_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_id_almacen_fkey FOREIGN KEY (id_almacen) REFERENCES public.almacenes(id_almacen) ON DELETE CASCADE;


--
-- Name: politicas_stock politicas_stock_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo) ON DELETE CASCADE;


--
-- Name: proveedor_insumo proveedor_insumo_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor_insumo
    ADD CONSTRAINT proveedor_insumo_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo) ON DELETE CASCADE;


--
-- Name: proveedor_insumo proveedor_insumo_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor_insumo
    ADD CONSTRAINT proveedor_insumo_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor) ON DELETE CASCADE;


--
-- Name: proveedores proveedores_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: proveedores proveedores_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: recepcion_detalles recepcion_detalles_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepcion_detalles
    ADD CONSTRAINT recepcion_detalles_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: recepcion_detalles recepcion_detalles_id_orden_detalle_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepcion_detalles
    ADD CONSTRAINT recepcion_detalles_id_orden_detalle_fkey FOREIGN KEY (id_orden_detalle) REFERENCES public.orden_compra_detalles(id_orden_detalle);


--
-- Name: recepcion_detalles recepcion_detalles_id_recepcion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepcion_detalles
    ADD CONSTRAINT recepcion_detalles_id_recepcion_fkey FOREIGN KEY (id_recepcion) REFERENCES public.recepciones_compra(id_recepcion) ON DELETE CASCADE;


--
-- Name: recepciones_compra recepciones_compra_id_almacen_destino_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_id_almacen_destino_fkey FOREIGN KEY (id_almacen_destino) REFERENCES public.almacenes(id_almacen);


--
-- Name: recepciones_compra recepciones_compra_id_orden_compra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_id_orden_compra_fkey FOREIGN KEY (id_orden_compra) REFERENCES public.ordenes_compra(id_orden_compra);


--
-- Name: recepciones_compra recepciones_compra_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor);


--
-- Name: recepciones_compra recepciones_compra_id_responsable_recepcion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_id_responsable_recepcion_fkey FOREIGN KEY (id_responsable_recepcion) REFERENCES public.usuarios(id_usuario);


--
-- Name: reservas_stock reservas_stock_id_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_almacen_fkey FOREIGN KEY (id_almacen) REFERENCES public.almacenes(id_almacen);


--
-- Name: reservas_stock reservas_stock_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: reservas_stock reservas_stock_id_inventario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_inventario_fkey FOREIGN KEY (id_inventario) REFERENCES public.inventarios(id_inventario) ON DELETE CASCADE;


--
-- Name: reservas_stock reservas_stock_id_pedido_detalle_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_pedido_detalle_fkey FOREIGN KEY (id_pedido_detalle) REFERENCES public.pedido_detalles(id_pedido_detalle) ON DELETE CASCADE;


--
-- Name: reservas_stock reservas_stock_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido) ON DELETE CASCADE;


--
-- Name: roles_permisos roles_permisos_id_permiso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_id_permiso_fkey FOREIGN KEY (id_permiso) REFERENCES public.permisos(id_permiso) ON DELETE CASCADE;


--
-- Name: roles_permisos roles_permisos_id_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol) ON DELETE CASCADE;


--
-- Name: tipos_insumo tipos_insumo_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipos_insumo
    ADD CONSTRAINT tipos_insumo_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: usuarios usuarios_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: usuarios usuarios_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: usuarios usuarios_id_area_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_id_area_fkey FOREIGN KEY (id_area) REFERENCES public.areas(id_area);


--
-- Name: usuarios usuarios_id_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol);


--
-- PostgreSQL database dump complete
--

\unrestrict 72gIr8jKbTZLfdHE1dxRnNsLMAXRD8bMiXg3OeO4awpfUkb9cuvq97B230SgUVq


