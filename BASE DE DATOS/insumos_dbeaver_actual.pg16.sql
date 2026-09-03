--
-- PostgreSQL database dump
--


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

ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_id_rol_fkey;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_id_area_fkey;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_actualizado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.tipos_insumo DROP CONSTRAINT IF EXISTS tipos_insumo_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.roles_permisos DROP CONSTRAINT IF EXISTS roles_permisos_id_rol_fkey;
ALTER TABLE IF EXISTS ONLY public.roles_permisos DROP CONSTRAINT IF EXISTS roles_permisos_id_permiso_fkey;
ALTER TABLE IF EXISTS ONLY public.reservas_stock DROP CONSTRAINT IF EXISTS reservas_stock_id_pedido_fkey;
ALTER TABLE IF EXISTS ONLY public.reservas_stock DROP CONSTRAINT IF EXISTS reservas_stock_id_pedido_detalle_fkey;
ALTER TABLE IF EXISTS ONLY public.reservas_stock DROP CONSTRAINT IF EXISTS reservas_stock_id_inventario_fkey;
ALTER TABLE IF EXISTS ONLY public.reservas_stock DROP CONSTRAINT IF EXISTS reservas_stock_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.reservas_stock DROP CONSTRAINT IF EXISTS reservas_stock_id_almacen_fkey;
ALTER TABLE IF EXISTS ONLY public.recepciones_compra DROP CONSTRAINT IF EXISTS recepciones_compra_id_responsable_recepcion_fkey;
ALTER TABLE IF EXISTS ONLY public.recepciones_compra DROP CONSTRAINT IF EXISTS recepciones_compra_id_proveedor_fkey;
ALTER TABLE IF EXISTS ONLY public.recepciones_compra DROP CONSTRAINT IF EXISTS recepciones_compra_id_orden_compra_fkey;
ALTER TABLE IF EXISTS ONLY public.recepciones_compra DROP CONSTRAINT IF EXISTS recepciones_compra_id_almacen_destino_fkey;
ALTER TABLE IF EXISTS ONLY public.recepcion_detalles DROP CONSTRAINT IF EXISTS recepcion_detalles_id_recepcion_fkey;
ALTER TABLE IF EXISTS ONLY public.recepcion_detalles DROP CONSTRAINT IF EXISTS recepcion_detalles_id_orden_detalle_fkey;
ALTER TABLE IF EXISTS ONLY public.recepcion_detalles DROP CONSTRAINT IF EXISTS recepcion_detalles_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.proveedores DROP CONSTRAINT IF EXISTS proveedores_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.proveedores DROP CONSTRAINT IF EXISTS proveedores_actualizado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.proveedor_insumo DROP CONSTRAINT IF EXISTS proveedor_insumo_id_proveedor_fkey;
ALTER TABLE IF EXISTS ONLY public.proveedor_insumo DROP CONSTRAINT IF EXISTS proveedor_insumo_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.politicas_stock DROP CONSTRAINT IF EXISTS politicas_stock_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.politicas_stock DROP CONSTRAINT IF EXISTS politicas_stock_id_almacen_fkey;
ALTER TABLE IF EXISTS ONLY public.politicas_stock DROP CONSTRAINT IF EXISTS politicas_stock_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.pedidos DROP CONSTRAINT IF EXISTS pedidos_id_usuario_solicitante_fkey;
ALTER TABLE IF EXISTS ONLY public.pedidos DROP CONSTRAINT IF EXISTS pedidos_id_usuario_revisor_fkey;
ALTER TABLE IF EXISTS ONLY public.pedidos DROP CONSTRAINT IF EXISTS pedidos_id_proveedor_sugerido_fkey;
ALTER TABLE IF EXISTS ONLY public.pedidos DROP CONSTRAINT IF EXISTS pedidos_id_area_solicitante_fkey;
ALTER TABLE IF EXISTS ONLY public.pedidos DROP CONSTRAINT IF EXISTS pedidos_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.pedidos DROP CONSTRAINT IF EXISTS pedidos_actualizado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.pedido_detalles DROP CONSTRAINT IF EXISTS pedido_detalles_id_pedido_fkey;
ALTER TABLE IF EXISTS ONLY public.pedido_detalles DROP CONSTRAINT IF EXISTS pedido_detalles_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.ordenes_compra DROP CONSTRAINT IF EXISTS ordenes_compra_usuario_genera_fkey;
ALTER TABLE IF EXISTS ONLY public.ordenes_compra DROP CONSTRAINT IF EXISTS ordenes_compra_id_proveedor_fkey;
ALTER TABLE IF EXISTS ONLY public.ordenes_compra DROP CONSTRAINT IF EXISTS ordenes_compra_id_pedido_fkey;
ALTER TABLE IF EXISTS ONLY public.orden_compra_detalles DROP CONSTRAINT IF EXISTS orden_compra_detalles_id_orden_compra_fkey;
ALTER TABLE IF EXISTS ONLY public.orden_compra_detalles DROP CONSTRAINT IF EXISTS orden_compra_detalles_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.notificaciones DROP CONSTRAINT IF EXISTS notificaciones_usuario_genera_fkey;
ALTER TABLE IF EXISTS ONLY public.notificaciones DROP CONSTRAINT IF EXISTS notificaciones_id_usuario_destinatario_fkey;
ALTER TABLE IF EXISTS ONLY public.movimientos_inventario DROP CONSTRAINT IF EXISTS movimientos_inventario_usuario_responsable_fkey;
ALTER TABLE IF EXISTS ONLY public.movimientos_inventario DROP CONSTRAINT IF EXISTS movimientos_inventario_id_recepcion_fkey;
ALTER TABLE IF EXISTS ONLY public.movimientos_inventario DROP CONSTRAINT IF EXISTS movimientos_inventario_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.movimientos_inventario DROP CONSTRAINT IF EXISTS movimientos_inventario_id_despacho_fkey;
ALTER TABLE IF EXISTS ONLY public.movimientos_inventario DROP CONSTRAINT IF EXISTS movimientos_inventario_id_almacen_origen_fkey;
ALTER TABLE IF EXISTS ONLY public.movimientos_inventario DROP CONSTRAINT IF EXISTS movimientos_inventario_id_almacen_destino_fkey;
ALTER TABLE IF EXISTS ONLY public.inventarios DROP CONSTRAINT IF EXISTS inventarios_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.inventarios DROP CONSTRAINT IF EXISTS inventarios_id_almacen_fkey;
ALTER TABLE IF EXISTS ONLY public.inventarios DROP CONSTRAINT IF EXISTS inventarios_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.inventarios DROP CONSTRAINT IF EXISTS inventarios_actualizado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_id_unidad_medida_secundaria_fkey;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_id_unidad_medida_fkey;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_id_tipo_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_id_categoria_fkey;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_actualizado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.despachos DROP CONSTRAINT IF EXISTS despachos_usuario_registra_fkey;
ALTER TABLE IF EXISTS ONLY public.despachos DROP CONSTRAINT IF EXISTS despachos_id_usuario_solicitante_fkey;
ALTER TABLE IF EXISTS ONLY public.despachos DROP CONSTRAINT IF EXISTS despachos_id_responsable_almacen_fkey;
ALTER TABLE IF EXISTS ONLY public.despachos DROP CONSTRAINT IF EXISTS despachos_id_pedido_fkey;
ALTER TABLE IF EXISTS ONLY public.despachos DROP CONSTRAINT IF EXISTS despachos_id_area_solicitante_fkey;
ALTER TABLE IF EXISTS ONLY public.despachos DROP CONSTRAINT IF EXISTS despachos_id_almacen_salida_fkey;
ALTER TABLE IF EXISTS ONLY public.despacho_detalles DROP CONSTRAINT IF EXISTS despacho_detalles_id_insumo_fkey;
ALTER TABLE IF EXISTS ONLY public.despacho_detalles DROP CONSTRAINT IF EXISTS despacho_detalles_id_despacho_fkey;
ALTER TABLE IF EXISTS ONLY public.comprobantes_compra DROP CONSTRAINT IF EXISTS comprobantes_compra_usuario_registra_fkey;
ALTER TABLE IF EXISTS ONLY public.comprobantes_compra DROP CONSTRAINT IF EXISTS comprobantes_compra_id_proveedor_fkey;
ALTER TABLE IF EXISTS ONLY public.comprobantes_compra DROP CONSTRAINT IF EXISTS comprobantes_compra_id_orden_compra_fkey;
ALTER TABLE IF EXISTS ONLY public.categorias_insumo DROP CONSTRAINT IF EXISTS categorias_insumo_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.auditorias DROP CONSTRAINT IF EXISTS auditorias_id_usuario_fkey;
ALTER TABLE IF EXISTS ONLY public.aprobaciones_pedido DROP CONSTRAINT IF EXISTS aprobaciones_pedido_id_usuario_aprobador_fkey;
ALTER TABLE IF EXISTS ONLY public.aprobaciones_pedido DROP CONSTRAINT IF EXISTS aprobaciones_pedido_id_pedido_fkey;
ALTER TABLE IF EXISTS ONLY public.almacenes DROP CONSTRAINT IF EXISTS almacenes_id_responsable_suplente_fkey;
ALTER TABLE IF EXISTS ONLY public.almacenes DROP CONSTRAINT IF EXISTS almacenes_id_responsable_principal_fkey;
ALTER TABLE IF EXISTS ONLY public.almacenes DROP CONSTRAINT IF EXISTS almacenes_creado_por_fkey;
ALTER TABLE IF EXISTS ONLY public.almacenes DROP CONSTRAINT IF EXISTS almacenes_actualizado_por_fkey;
DROP TRIGGER IF EXISTS trg_recepcion_actualiza_inventario ON public.recepcion_detalles;
DROP TRIGGER IF EXISTS trg_despacho_actualiza_inventario ON public.despacho_detalles;
DROP INDEX IF EXISTS public.ux_usuarios_cedula_identidad;
DROP INDEX IF EXISTS public.idx_usuarios_rol;
DROP INDEX IF EXISTS public.idx_usuarios_estado_no_eliminado;
DROP INDEX IF EXISTS public.idx_usuarios_area;
DROP INDEX IF EXISTS public.idx_proveedores_estado_no_eliminado;
DROP INDEX IF EXISTS public.idx_pedidos_estado;
DROP INDEX IF EXISTS public.idx_pedidos_area;
DROP INDEX IF EXISTS public.idx_ordenes_proveedor;
DROP INDEX IF EXISTS public.idx_notificaciones_usuario_estado;
DROP INDEX IF EXISTS public.idx_movimientos_insumo_fecha;
DROP INDEX IF EXISTS public.idx_movimientos_id_recepcion;
DROP INDEX IF EXISTS public.idx_movimientos_id_despacho;
DROP INDEX IF EXISTS public.idx_movimientos_codigo_referencia;
DROP INDEX IF EXISTS public.idx_inventarios_insumo;
DROP INDEX IF EXISTS public.idx_inventarios_almacen;
DROP INDEX IF EXISTS public.idx_insumos_tipo;
DROP INDEX IF EXISTS public.idx_insumos_estado_no_eliminado;
DROP INDEX IF EXISTS public.idx_insumos_categoria;
DROP INDEX IF EXISTS public.idx_despachos_pedido;
DROP INDEX IF EXISTS public.idx_auditorias_usuario_fecha;
DROP INDEX IF EXISTS public.idx_almacenes_estado_no_eliminado;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_pkey;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_nombre_usuario_key;
ALTER TABLE IF EXISTS ONLY public.usuarios DROP CONSTRAINT IF EXISTS usuarios_correo_key;
ALTER TABLE IF EXISTS ONLY public.unidades_medida DROP CONSTRAINT IF EXISTS unidades_medida_pkey;
ALTER TABLE IF EXISTS ONLY public.unidades_medida DROP CONSTRAINT IF EXISTS unidades_medida_nombre_unidad_key;
ALTER TABLE IF EXISTS ONLY public.unidades_medida DROP CONSTRAINT IF EXISTS unidades_medida_abreviatura_key;
ALTER TABLE IF EXISTS ONLY public.tipos_insumo DROP CONSTRAINT IF EXISTS tipos_insumo_pkey;
ALTER TABLE IF EXISTS ONLY public.tipos_insumo DROP CONSTRAINT IF EXISTS tipos_insumo_nombre_tipo_key;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_pkey;
ALTER TABLE IF EXISTS ONLY public.roles_permisos DROP CONSTRAINT IF EXISTS roles_permisos_pkey;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_nombre_rol_key;
ALTER TABLE IF EXISTS ONLY public.reservas_stock DROP CONSTRAINT IF EXISTS reservas_stock_pkey;
ALTER TABLE IF EXISTS ONLY public.reservas_stock DROP CONSTRAINT IF EXISTS reservas_stock_id_pedido_detalle_id_almacen_key;
ALTER TABLE IF EXISTS ONLY public.recepciones_compra DROP CONSTRAINT IF EXISTS recepciones_compra_pkey;
ALTER TABLE IF EXISTS ONLY public.recepciones_compra DROP CONSTRAINT IF EXISTS recepciones_compra_numero_recepcion_key;
ALTER TABLE IF EXISTS ONLY public.recepcion_detalles DROP CONSTRAINT IF EXISTS recepcion_detalles_pkey;
ALTER TABLE IF EXISTS ONLY public.proveedores DROP CONSTRAINT IF EXISTS proveedores_pkey;
ALTER TABLE IF EXISTS ONLY public.proveedores DROP CONSTRAINT IF EXISTS proveedores_nit_key;
ALTER TABLE IF EXISTS ONLY public.proveedores DROP CONSTRAINT IF EXISTS proveedores_codigo_proveedor_key;
ALTER TABLE IF EXISTS ONLY public.proveedor_insumo DROP CONSTRAINT IF EXISTS proveedor_insumo_pkey;
ALTER TABLE IF EXISTS ONLY public.politicas_stock DROP CONSTRAINT IF EXISTS politicas_stock_pkey;
ALTER TABLE IF EXISTS ONLY public.politicas_stock DROP CONSTRAINT IF EXISTS politicas_stock_id_insumo_id_almacen_key;
ALTER TABLE IF EXISTS ONLY public.permisos DROP CONSTRAINT IF EXISTS permisos_pkey;
ALTER TABLE IF EXISTS ONLY public.permisos DROP CONSTRAINT IF EXISTS permisos_codigo_permiso_key;
ALTER TABLE IF EXISTS ONLY public.pedidos DROP CONSTRAINT IF EXISTS pedidos_pkey;
ALTER TABLE IF EXISTS ONLY public.pedidos DROP CONSTRAINT IF EXISTS pedidos_numero_pedido_key;
ALTER TABLE IF EXISTS ONLY public.pedido_detalles DROP CONSTRAINT IF EXISTS pedido_detalles_pkey;
ALTER TABLE IF EXISTS ONLY public.ordenes_compra DROP CONSTRAINT IF EXISTS ordenes_compra_pkey;
ALTER TABLE IF EXISTS ONLY public.ordenes_compra DROP CONSTRAINT IF EXISTS ordenes_compra_numero_orden_key;
ALTER TABLE IF EXISTS ONLY public.ordenes_compra DROP CONSTRAINT IF EXISTS ordenes_compra_codigo_correlativo_key;
ALTER TABLE IF EXISTS ONLY public.orden_compra_detalles DROP CONSTRAINT IF EXISTS orden_compra_detalles_pkey;
ALTER TABLE IF EXISTS ONLY public.notificaciones DROP CONSTRAINT IF EXISTS notificaciones_pkey;
ALTER TABLE IF EXISTS ONLY public.movimientos_inventario DROP CONSTRAINT IF EXISTS movimientos_inventario_pkey;
ALTER TABLE IF EXISTS ONLY public.movimientos_inventario DROP CONSTRAINT IF EXISTS movimientos_inventario_numero_movimiento_key;
ALTER TABLE IF EXISTS ONLY public.inventarios DROP CONSTRAINT IF EXISTS inventarios_pkey;
ALTER TABLE IF EXISTS ONLY public.inventarios DROP CONSTRAINT IF EXISTS inventarios_id_insumo_id_almacen_key;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_pkey;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_codigo_interno_key;
ALTER TABLE IF EXISTS ONLY public.insumos DROP CONSTRAINT IF EXISTS insumos_codigo_barra_qr_key;
ALTER TABLE IF EXISTS ONLY public.despachos DROP CONSTRAINT IF EXISTS despachos_pkey;
ALTER TABLE IF EXISTS ONLY public.despachos DROP CONSTRAINT IF EXISTS despachos_numero_despacho_key;
ALTER TABLE IF EXISTS ONLY public.despacho_detalles DROP CONSTRAINT IF EXISTS despacho_detalles_pkey;
ALTER TABLE IF EXISTS ONLY public.comprobantes_compra DROP CONSTRAINT IF EXISTS comprobantes_compra_pkey;
ALTER TABLE IF EXISTS ONLY public.comprobantes_compra DROP CONSTRAINT IF EXISTS comprobantes_compra_numero_comprobante_key;
ALTER TABLE IF EXISTS ONLY public.categorias_insumo DROP CONSTRAINT IF EXISTS categorias_insumo_pkey;
ALTER TABLE IF EXISTS ONLY public.categorias_insumo DROP CONSTRAINT IF EXISTS categorias_insumo_nombre_categoria_key;
ALTER TABLE IF EXISTS ONLY public.auditorias DROP CONSTRAINT IF EXISTS auditorias_pkey;
ALTER TABLE IF EXISTS ONLY public.areas DROP CONSTRAINT IF EXISTS areas_pkey;
ALTER TABLE IF EXISTS ONLY public.areas DROP CONSTRAINT IF EXISTS areas_nombre_area_key;
ALTER TABLE IF EXISTS ONLY public.aprobaciones_pedido DROP CONSTRAINT IF EXISTS aprobaciones_pedido_pkey;
ALTER TABLE IF EXISTS ONLY public.almacenes DROP CONSTRAINT IF EXISTS almacenes_pkey;
ALTER TABLE IF EXISTS ONLY public.almacenes DROP CONSTRAINT IF EXISTS almacenes_codigo_almacen_key;
DROP VIEW IF EXISTS public.v_pedidos_por_estado;
DROP VIEW IF EXISTS public.v_kardex;
DROP VIEW IF EXISTS public.v_dashboard_resumen;
DROP VIEW IF EXISTS public.v_stock_bajo;
DROP VIEW IF EXISTS public.v_stock_actual;
DROP VIEW IF EXISTS public.v_compras_por_proveedor;
DROP TABLE IF EXISTS public.usuarios;
DROP TABLE IF EXISTS public.unidades_medida;
DROP TABLE IF EXISTS public.tipos_insumo;
DROP TABLE IF EXISTS public.roles_permisos;
DROP TABLE IF EXISTS public.roles;
DROP TABLE IF EXISTS public.reservas_stock;
DROP TABLE IF EXISTS public.recepciones_compra;
DROP TABLE IF EXISTS public.recepcion_detalles;
DROP TABLE IF EXISTS public.proveedores;
DROP TABLE IF EXISTS public.proveedor_insumo;
DROP TABLE IF EXISTS public.politicas_stock;
DROP TABLE IF EXISTS public.permisos;
DROP TABLE IF EXISTS public.pedidos;
DROP TABLE IF EXISTS public.pedido_detalles;
DROP TABLE IF EXISTS public.ordenes_compra;
DROP TABLE IF EXISTS public.orden_compra_detalles;
DROP TABLE IF EXISTS public.notificaciones;
DROP TABLE IF EXISTS public.movimientos_inventario;
DROP TABLE IF EXISTS public.inventarios;
DROP TABLE IF EXISTS public.insumos;
DROP TABLE IF EXISTS public.despachos;
DROP TABLE IF EXISTS public.despacho_detalles;
DROP TABLE IF EXISTS public.comprobantes_compra;
DROP TABLE IF EXISTS public.categorias_insumo;
DROP TABLE IF EXISTS public.auditorias;
DROP TABLE IF EXISTS public.areas;
DROP TABLE IF EXISTS public.aprobaciones_pedido;
DROP TABLE IF EXISTS public.almacenes;
DROP FUNCTION IF EXISTS public.fn_recepcion_actualiza_inventario();
DROP FUNCTION IF EXISTS public.fn_despacho_actualiza_inventario();
--
-- Name: fn_despacho_actualiza_inventario(); Type: FUNCTION; Schema: public; Owner: -
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
        SELECT d.id_almacen_salida, d.id_responsable_almacen, d.id_pedido, d.numero_despacho
        INTO v_almacen, v_usuario, v_id_pedido, v_numero_despacho
        FROM despachos d
        WHERE d.id_despacho = NEW.id_despacho;

        SELECT i.stock_fisico, i.stock_reservado, i.costo_promedio
        INTO v_stock_fisico, v_stock_reservado, v_costo
        FROM inventarios i
        WHERE i.id_insumo = NEW.id_insumo
          AND i.id_almacen = v_almacen
        FOR UPDATE;

        SELECT COALESCE(SUM(rs.cantidad_reservada), 0)
        INTO v_reservado_pedido
        FROM reservas_stock rs
        WHERE rs.id_pedido = v_id_pedido
          AND rs.id_insumo = NEW.id_insumo
          AND rs.id_almacen = v_almacen
          AND rs.estado = 'ACTIVA';

        IF COALESCE(v_stock_fisico, 0) < NEW.cantidad_entregada
           OR (
             v_reservado_pedido < NEW.cantidad_entregada
             AND COALESCE(v_stock_fisico, 0) - COALESCE(v_stock_reservado, 0) < NEW.cantidad_entregada
           ) THEN
            RAISE EXCEPTION 'Stock insuficiente para el insumo %. Stock fisico: %, reservado para pedido: %, cantidad solicitada: %',
                NEW.id_insumo, COALESCE(v_stock_fisico, 0), COALESCE(v_reservado_pedido, 0), NEW.cantidad_entregada;
        END IF;

        UPDATE inventarios
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

        INSERT INTO movimientos_inventario (
            numero_movimiento, tipo_movimiento, id_insumo, id_almacen_origen,
            cantidad, costo_unitario, motivo, documento_respaldo, usuario_responsable, observaciones
        )
        VALUES (
            'MOV-DES-' || NEW.id_despacho_detalle,
            'SALIDA_DESPACHO',
            NEW.id_insumo,
            v_almacen,
            NEW.cantidad_entregada,
            COALESCE(v_costo, 0),
            'Salida automática por despacho de insumos',
            v_numero_despacho,
            v_usuario,
            'Movimiento generado automáticamente desde despacho.'
        );
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: fn_recepcion_actualiza_inventario(); Type: FUNCTION; Schema: public; Owner: -
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: almacenes; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: almacenes_id_almacen_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: aprobaciones_pedido; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: aprobaciones_pedido_id_aprobacion_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: areas; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: areas_id_area_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: auditorias; Type: TABLE; Schema: public; Owner: -
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
    CONSTRAINT auditorias_tipo_accion_check CHECK (((tipo_accion)::text = ANY ((ARRAY['CREAR'::character varying, 'EDITAR'::character varying, 'ELIMINAR'::character varying, 'ACTIVAR'::character varying, 'DESACTIVAR'::character varying, 'APROBAR'::character varying, 'RECHAZAR'::character varying, 'ANULAR'::character varying, 'LOGIN'::character varying, 'LOGOUT'::character varying, 'CONSULTAR'::character varying, 'REGISTRAR_COMPRA'::character varying, 'REGISTRAR_RECEPCION'::character varying, 'REGISTRAR_COMPROBANTE'::character varying, 'REALIZAR_DESPACHO'::character varying, 'AJUSTAR_INVENTARIO'::character varying, 'INICIAR_SESION'::character varying, 'CERRAR_SESION'::character varying, 'CAMBIAR_CONTRASENA'::character varying, 'CAMBIAR_PERMISOS'::character varying, 'ACCESO_DENEGADO'::character varying])::text[])))
);


--
-- Name: auditorias_id_auditoria_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: categorias_insumo; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: categorias_insumo_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: comprobantes_compra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comprobantes_compra (
    id_comprobante integer NOT NULL,
    numero_comprobante character varying(60) NOT NULL,
    tipo_comprobante character varying(40) NOT NULL,
    fecha_comprobante timestamp with time zone DEFAULT now() NOT NULL,
    id_proveedor integer NOT NULL,
    nit_proveedor character varying(30) NOT NULL,
    id_orden_compra integer NOT NULL,
    monto_subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    monto_descuento numeric(14,2) DEFAULT 0 NOT NULL,
    monto_total numeric(14,2) GENERATED ALWAYS AS ((monto_subtotal - monto_descuento)) STORED,
    moneda character varying(10) DEFAULT 'BOB'::character varying NOT NULL,
    estado_comprobante character varying(30) DEFAULT 'REGISTRADO'::character varying NOT NULL,
    archivo_comprobante character varying(255),
    observaciones text,
    usuario_registra integer,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT comprobantes_compra_estado_comprobante_check CHECK (((estado_comprobante)::text = ANY ((ARRAY['REGISTRADO'::character varying, 'OBSERVADO'::character varying, 'ANULADO'::character varying])::text[]))),
    CONSTRAINT comprobantes_compra_monto_descuento_check CHECK ((monto_descuento >= (0)::numeric)),
    CONSTRAINT comprobantes_compra_monto_subtotal_check CHECK ((monto_subtotal >= (0)::numeric)),
    CONSTRAINT comprobantes_compra_tipo_comprobante_check CHECK (((tipo_comprobante)::text = ANY ((ARRAY['FACTURA'::character varying, 'RECIBO'::character varying, 'NOTA_VENTA'::character varying, 'COMPROBANTE_INTERNO'::character varying, 'OTRO'::character varying])::text[])))
);


--
-- Name: comprobantes_compra_id_comprobante_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: despacho_detalles; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: despacho_detalles_id_despacho_detalle_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: despachos; Type: TABLE; Schema: public; Owner: -
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
    CONSTRAINT despachos_estado_despacho_check CHECK (((estado_despacho)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'PENDIENTE_ENTREGA'::character varying, 'PREPARADO'::character varying, 'ENTREGADO_PARCIAL'::character varying, 'ENTREGADO_COMPLETO'::character varying, 'CANCELADO'::character varying, 'OBSERVADO'::character varying])::text[]))),
    CONSTRAINT despachos_tipo_despacho_check CHECK (((tipo_despacho)::text = ANY ((ARRAY['NORMAL'::character varying, 'URGENTE'::character varying, 'PARCIAL'::character varying, 'DEVOLUCION'::character varying, 'REPOSICION'::character varying])::text[])))
);


--
-- Name: despachos_id_despacho_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: insumos; Type: TABLE; Schema: public; Owner: -
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
    stock_minimo numeric(14,2) DEFAULT 0 NOT NULL,
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
    CONSTRAINT insumos_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying, 'ELIMINADO'::character varying])::text[]))),
    CONSTRAINT insumos_precio_referencial_check CHECK ((precio_referencial >= (0)::numeric)),
    CONSTRAINT insumos_stock_minimo_check CHECK ((stock_minimo >= (0)::numeric))
);


--
-- Name: insumos_id_insumo_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: inventarios; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: inventarios_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: movimientos_inventario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movimientos_inventario (
    id_movimiento integer NOT NULL,
    numero_movimiento character varying(40) NOT NULL,
    fecha_movimiento timestamp with time zone DEFAULT now() NOT NULL,
    tipo_movimiento character varying(40) NOT NULL,
    id_insumo integer NOT NULL,
    id_almacen_origen integer,
    id_almacen_destino integer,
    id_despacho integer,
    id_recepcion integer,
    codigo_referencia character varying(60),
    cantidad numeric(14,2) NOT NULL,
    costo_unitario numeric(14,2) DEFAULT 0,
    motivo text NOT NULL,
    documento_respaldo character varying(255),
    usuario_responsable integer,
    observaciones text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT movimientos_inventario_cantidad_check CHECK ((cantidad > (0)::numeric)),
    CONSTRAINT movimientos_inventario_costo_unitario_check CHECK ((costo_unitario >= (0)::numeric)),
    CONSTRAINT movimientos_inventario_tipo_movimiento_check CHECK (((tipo_movimiento)::text = ANY ((ARRAY['ENTRADA_COMPRA'::character varying, 'SALIDA_DESPACHO'::character varying, 'AJUSTE_POSITIVO'::character varying, 'AJUSTE_NEGATIVO'::character varying, 'DEVOLUCION'::character varying, 'TRANSFERENCIA_SALIDA'::character varying, 'TRANSFERENCIA_ENTRADA'::character varying])::text[])))
);


--
-- Name: movimientos_inventario_id_movimiento_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: notificaciones; Type: TABLE; Schema: public; Owner: -
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
    CONSTRAINT notificaciones_tipo_notificacion_check CHECK (((tipo_notificacion)::text = ANY ((ARRAY['STOCK_BAJO'::character varying, 'INSUMO_SIN_STOCK'::character varying, 'PEDIDO_CREADO'::character varying, 'PEDIDO_APROBADO'::character varying, 'PEDIDO_RECHAZADO'::character varying, 'PEDIDO_OBSERVADO'::character varying, 'PEDIDO_EN_COMPRA'::character varying, 'COMPRA_REGISTRADA'::character varying, 'COMPRA_RECIBIDA_PARCIAL'::character varying, 'COMPRA_RECIBIDA_COMPLETA'::character varying, 'DESPACHO_REALIZADO'::character varying, 'COMPROBANTE_REGISTRADO'::character varying, 'COMPROBANTE_OBSERVADO'::character varying, 'TRANSFERENCIA_REGISTRADA'::character varying, 'DEVOLUCION_REGISTRADA'::character varying, 'USUARIO_CREADO'::character varying, 'AUDITORIA_IMPORTANTE'::character varying])::text[])))
);


--
-- Name: notificaciones_id_notificacion_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: orden_compra_detalles; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: orden_compra_detalles_id_orden_detalle_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: ordenes_compra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ordenes_compra (
    id_orden_compra integer NOT NULL,
    numero_orden character varying(40) NOT NULL,
    codigo_correlativo character varying(40) NOT NULL,
    id_pedido integer,
    id_proveedor integer NOT NULL,
    fecha_emision timestamp with time zone DEFAULT now() NOT NULL,
    fecha_estimada_entrega timestamp with time zone,
    condicion_pago character varying(120),
    forma_pago character varying(120),
    moneda character varying(10) DEFAULT 'BOB'::character varying NOT NULL,
    estado_pago character varying(30) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    subtotal numeric(14,2) DEFAULT 0 NOT NULL,
    descuento numeric(14,2) DEFAULT 0 NOT NULL,
    total_final numeric(14,2) GENERATED ALWAYS AS ((subtotal - descuento)) STORED,
    estado_compra character varying(40) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    observaciones text,
    usuario_genera integer,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    CONSTRAINT ordenes_compra_descuento_check CHECK ((descuento >= (0)::numeric)),
    CONSTRAINT ordenes_compra_estado_compra_check CHECK (((estado_compra)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'EN_PROCESO'::character varying, 'RECIBIDA_PARCIAL'::character varying, 'RECIBIDA_COMPLETA'::character varying, 'ANULADA'::character varying])::text[]))),
    CONSTRAINT ordenes_compra_estado_pago_check CHECK (((estado_pago)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'PAGADO_PARCIAL'::character varying, 'PAGADO_COMPLETO'::character varying, 'ANULADO'::character varying])::text[]))),
    CONSTRAINT ordenes_compra_subtotal_check CHECK ((subtotal >= (0)::numeric))
);


--
-- Name: ordenes_compra_id_orden_compra_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: pedido_detalles; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: pedido_detalles_id_pedido_detalle_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: pedidos; Type: TABLE; Schema: public; Owner: -
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
    lugar_uso character varying(120),
    turno_guardia character varying(80),
    observaciones text,
    id_usuario_revisor integer,
    fecha_revision timestamp with time zone,
    motivo_rechazo text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp with time zone,
    creado_por integer,
    actualizado_por integer,
    CONSTRAINT pedidos_estado_aprobacion_check CHECK (((estado_aprobacion)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'APROBADO'::character varying, 'RECHAZADO'::character varying, 'OBSERVADO'::character varying])::text[]))),
    CONSTRAINT pedidos_estado_atencion_check CHECK (((estado_atencion)::text = ANY ((ARRAY['SIN_ATENDER'::character varying, 'EN_PROCESO'::character varying, 'ATENDIDO_PARCIAL'::character varying, 'ATENDIDO_TOTAL'::character varying])::text[]))),
    CONSTRAINT pedidos_estado_pedido_check CHECK (((estado_pedido)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'APROBADO'::character varying, 'RECHAZADO'::character varying, 'OBSERVADO'::character varying, 'EN_COMPRA'::character varying, 'EN_DESPACHO'::character varying, 'ENTREGADO_PARCIAL'::character varying, 'ENTREGADO_COMPLETO'::character varying, 'CANCELADO'::character varying])::text[]))),
    CONSTRAINT pedidos_prioridad_check CHECK (((prioridad)::text = ANY ((ARRAY['BAJA'::character varying, 'MEDIA'::character varying, 'ALTA'::character varying, 'URGENTE'::character varying])::text[]))),
    CONSTRAINT pedidos_tipo_pedido_check CHECK (((tipo_pedido)::text = ANY ((ARRAY['NORMAL'::character varying, 'URGENTE'::character varying, 'REPOSICION'::character varying, 'EMERGENCIA'::character varying, 'MANTENIMIENTO'::character varying, 'OPERACION'::character varying])::text[])))
);


--
-- Name: pedidos_id_pedido_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permisos (
    id_permiso integer NOT NULL,
    codigo_permiso character varying(80) NOT NULL,
    modulo character varying(80) NOT NULL,
    descripcion text NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: politicas_stock; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: politicas_stock_id_politica_stock_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: proveedor_insumo; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: proveedores; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: proveedores_id_proveedor_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: recepcion_detalles; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: recepcion_detalles_id_recepcion_detalle_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: recepciones_compra; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recepciones_compra (
    id_recepcion integer NOT NULL,
    numero_recepcion character varying(40) NOT NULL,
    id_orden_compra integer NOT NULL,
    id_proveedor integer NOT NULL,
    id_almacen_destino integer NOT NULL,
    fecha_estimada_recepcion timestamp with time zone,
    fecha_real_recepcion timestamp with time zone DEFAULT now() NOT NULL,
    id_responsable_recepcion integer,
    estado_recepcion character varying(40) NOT NULL,
    documento_respaldo character varying(255),
    observaciones text,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT recepciones_compra_estado_recepcion_check CHECK (((estado_recepcion)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'RECIBIDA_PARCIAL'::character varying, 'RECIBIDA_COMPLETA'::character varying, 'OBSERVADA'::character varying, 'RECHAZADA'::character varying])::text[])))
);


--
-- Name: recepciones_compra_id_recepcion_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: reservas_stock; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: reservas_stock_id_reserva_stock_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: roles; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: roles_id_rol_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: roles_permisos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles_permisos (
    id_rol integer NOT NULL,
    id_permiso integer NOT NULL
);


--
-- Name: tipos_insumo; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: tipos_insumo_id_tipo_insumo_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: unidades_medida; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: unidades_medida_id_unidad_medida_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id_usuario integer NOT NULL,
    id_area integer NOT NULL,
    id_rol integer NOT NULL,
    nombre_completo character varying(150) NOT NULL,
    nombre_usuario character varying(80) NOT NULL,
    correo character varying(150),
    cedula_identidad character varying(30),
    complemento_ci character varying(10),
    expedido_ci character varying(20),
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
    CONSTRAINT usuarios_estado_check CHECK (((estado)::text = ANY ((ARRAY['ACTIVO'::character varying, 'INACTIVO'::character varying, 'ELIMINADO'::character varying])::text[]))),
    CONSTRAINT usuarios_intentos_fallidos_check CHECK ((intentos_fallidos >= 0))
);


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
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
-- Name: v_compras_por_proveedor; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_compras_por_proveedor AS
 SELECT p.codigo_proveedor,
    p.razon_social,
    count(oc.id_orden_compra) AS total_compras,
    COALESCE(sum(oc.total_final), (0)::numeric) AS monto_total_comprado
   FROM (public.proveedores p
     LEFT JOIN public.ordenes_compra oc ON ((oc.id_proveedor = p.id_proveedor)))
  GROUP BY p.codigo_proveedor, p.razon_social;


--
-- Name: v_stock_actual; Type: VIEW; Schema: public; Owner: -
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
    ins.stock_minimo,
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


--
-- Name: v_stock_bajo; Type: VIEW; Schema: public; Owner: -
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


--
-- Name: v_dashboard_resumen; Type: VIEW; Schema: public; Owner: -
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
          WHERE ((ordenes_compra.estado_compra)::text = ANY ((ARRAY['PENDIENTE'::character varying, 'EN_PROCESO'::character varying])::text[]))) AS compras_en_proceso,
    ( SELECT count(*) AS count
           FROM public.ordenes_compra
          WHERE ((ordenes_compra.estado_compra)::text = 'RECIBIDA_COMPLETA'::text)) AS compras_recibidas,
    ( SELECT count(*) AS count
           FROM public.v_stock_bajo) AS insumos_con_stock_bajo,
    ( SELECT COALESCE(sum(inventarios.valor_total_stock), (0)::numeric) AS "coalesce"
           FROM public.inventarios) AS valor_total_inventario;


--
-- Name: v_kardex; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_kardex AS
 SELECT mi.fecha_movimiento,
    mi.numero_movimiento,
    ins.codigo_interno,
    ins.nombre_insumo,
    mi.tipo_movimiento,
        CASE
            WHEN ((mi.tipo_movimiento)::text = ANY ((ARRAY['ENTRADA_COMPRA'::character varying, 'AJUSTE_POSITIVO'::character varying, 'DEVOLUCION'::character varying, 'TRANSFERENCIA_ENTRADA'::character varying])::text[])) THEN mi.cantidad
            ELSE (0)::numeric
        END AS entrada,
        CASE
            WHEN ((mi.tipo_movimiento)::text = ANY ((ARRAY['SALIDA_DESPACHO'::character varying, 'AJUSTE_NEGATIVO'::character varying, 'TRANSFERENCIA_SALIDA'::character varying])::text[])) THEN mi.cantidad
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


--
-- Name: v_pedidos_por_estado; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_pedidos_por_estado AS
 SELECT estado_pedido,
    count(*) AS total_pedidos
   FROM public.pedidos
  GROUP BY estado_pedido;


--
-- Data for Name: almacenes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.almacenes (id_almacen, codigo_almacen, nombre_almacen, tipo_almacen, ubicacion, id_responsable_principal, id_responsable_suplente, telefono_contacto, horario_atencion, descripcion, capacidad_maxima, capacidad_minima_recomendada, tipo_almacenamiento, observaciones_seguridad, estado, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
1	ALM-1	Polvorín	POLVORIN	interior mina porvenir -30	3	\N	74757677	lunes a viernes de 9:00 a 10:00 am	se almacena todo lo que es material de uso explosivo que no pueden estar en la superficie por normas de medio ambiente	\N	\N	\N	\N	ACTIVO	2026-08-13 19:36:44.726461+00	\N	\N	\N
2	ALM-2	seguridad industrial	SEGURIDAD_INDUSTRIAL	sector de reparto de material minera bocamina	4	\N	74758946	lunes a viernes 9:00 a 10:00 am	se despacha todo el material de trabajo que se utiliza dia a dia para los socios	\N	\N	\N	\N	ACTIVO	2026-08-13 20:01:17.038033+00	\N	\N	\N
3	ALM-3	combustible	COMBUSTIBLE	sector transporte	6	\N	65842595	lunes a viernes de 8:00 a 16:00	se despacha y se guarda toda lo que es combustible para posterior reparto a las máquinas de trabajo	\N	\N	\N	\N	ACTIVO	2026-08-13 20:03:59.508243+00	\N	\N	\N
\.


--
-- Data for Name: aprobaciones_pedido; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.aprobaciones_pedido (id_aprobacion, id_pedido, id_usuario_aprobador, nivel_aprobacion, fecha_aprobacion, estado_aprobacion, observaciones, motivo_rechazo, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: areas; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.areas (id_area, nombre_area, descripcion, estado, fecha_creacion, fecha_actualizacion) FROM stdin;
5	Compras	Area encargada de gestionar compras y proveedores.	ACTIVO	2026-08-13 20:47:27.723417+00	2026-08-15 12:41:00.801+00
6	Almacén	Area responsable del control fisico de insumos.	ACTIVO	2026-08-13 20:47:27.730096+00	2026-08-15 12:41:00.806+00
1	Administración	Area administrativa de apoyo.	ACTIVO	2026-08-05 19:50:07.067152+00	2026-08-15 12:41:00.811+00
7	Transporte	Area de apoyo logistico y transporte.	ACTIVO	2026-08-13 20:47:27.748735+00	2026-08-15 12:41:00.815+00
8	Perforación	Area encargada de trabajos de perforacion.	ACTIVO	2026-08-13 20:47:27.758149+00	2026-08-15 12:41:00.819+00
9	Operaciones	Area de coordinacion operativa.	ACTIVO	2026-08-13 20:47:27.765496+00	2026-08-15 12:41:00.823+00
10	Gerencia	Area de direccion y toma de decisiones.	ACTIVO	2026-08-13 20:47:27.773188+00	2026-08-15 12:41:00.827+00
11	Auditoría	Area de revision y control interno.	ACTIVO	2026-08-13 20:47:27.783016+00	2026-08-15 12:41:00.831+00
2	Mina	Area responsable de la operacion minera.	ACTIVO	2026-08-13 20:47:27.689456+00	2026-08-15 12:41:00.772+00
3	Mantenimiento	Area encargada del mantenimiento de equipos e infraestructura.	ACTIVO	2026-08-13 20:47:27.705636+00	2026-08-15 12:41:00.785+00
4	Seguridad Industrial	Area responsable de seguridad industrial y dotacion de EPP.	ACTIVO	2026-08-13 20:47:27.713104+00	2026-08-15 12:41:00.794+00
\.


--
-- Data for Name: auditorias; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.auditorias (id_auditoria, id_usuario, accion_realizada, tipo_accion, modulo_afectado, tabla_afectada, id_registro_afectado, registro_anterior, registro_nuevo, fecha_hora, direccion_ip, navegador_dispositivo, motivo_cambio, observaciones) FROM stdin;
1	1	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-08-05 20:04:07.290358+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
2	1	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-08-05 22:36:16.413681+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
3	\N	Login fallido de jperez	INICIAR_SESION	Autenticación	usuarios	\N	\N	{"motivo": "Usuario no encontrado", "resultado": "FALLIDO", "nombreUsuario": "jperez"}	2026-08-05 22:36:55.265843+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Usuario no encontrado	Intento de inicio de sesiÃ³n no autorizado.
4	1	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-08-13 19:12:52.183105+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
5	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	1	\N	{"cargo": "presidente de la cooperativa minera el porvenir R.L.", "idRol": 1, "correo": "feyckon@gmail.com", "estado": "ACTIVO", "idArea": 1, "telefono": "74477014", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "federico", "nombreCompleto": "federico choquecallata villca", "cedulaIdentidad": "12901305"}	2026-08-13 19:15:30.834205+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
6	1	Se creó un nuevo registro en Usuarios.	CREAR	Usuarios	usuarios	2	\N	{"cargo": "presidente del consejo de vigilancia", "idRol": 3, "correo": "miguel@gmail.com", "estado": "ACTIVO", "idArea": 1, "telefono": "75759535", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "miguel", "nombreCompleto": "miguel tipa lopez", "cedulaIdentidad": "1289654"}	2026-08-13 19:18:22.519718+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
7	1	Se creó un nuevo registro en Usuarios.	CREAR	Usuarios	usuarios	3	\N	{"cargo": "secretario del area de prevención social (material)", "idRol": 2, "correo": "jose@gmail.com", "estado": "ACTIVO", "idArea": 1, "telefono": "74757677", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "jose", "nombreCompleto": "jose cayoja condori", "cedulaIdentidad": "1263845"}	2026-08-13 19:31:13.756176+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
8	1	Se creó un nuevo registro en Almacenes.	CREAR	Almacenes	almacenes	1	\N	{"ubicacion": "interior mina porvenir -30", "descripcion": "se almacena todo lo que es material de uso explosivo que no pueden estar en la superficie por normas de medio ambiente", "idEncargado": 3, "tipoAlmacen": "POLVORIN", "codigoAlmacen": "ALM-1", "nombreAlmacen": "Polvorín", "horarioAtencion": "lunes a viernes de 9:00 a 10:00 am", "telefonoContacto": "74757677"}	2026-08-13 19:36:44.748886+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
9	1	Se creó un nuevo registro en Usuarios.	CREAR	Usuarios	usuarios	4	\N	{"cargo": "secretario de seguridad industrial", "idRol": 2, "correo": "juvenal@gmail.com", "estado": "ACTIVO", "idArea": 1, "telefono": "75747172", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "juve", "nombreCompleto": "juvenal choquecallata villca", "cedulaIdentidad": "1152694"}	2026-08-13 19:40:25.303697+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
10	1	Se creó un nuevo registro en Usuarios.	CREAR	Usuarios	usuarios	5	\N	{"cargo": "secretario de transporte", "idRol": 2, "correo": "fermin@gmail.com", "estado": "ACTIVO", "idArea": 1, "telefono": "75747695", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "fermin", "nombreCompleto": "fermin condori aguilar", "cedulaIdentidad": "12659858"}	2026-08-13 19:43:05.222207+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
11	1	Se creó un nuevo registro en Usuarios.	CREAR	Usuarios	usuarios	6	\N	{"cargo": "secretario de combustible minera", "idRol": 2, "correo": "martin@gmail.com", "estado": "ACTIVO", "idArea": 1, "telefono": "64958245", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "martin", "nombreCompleto": "martin arocha juntuta", "cedulaIdentidad": "1025869"}	2026-08-13 19:45:13.316291+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
12	1	Se creó un nuevo registro en Almacenes.	CREAR	Almacenes	almacenes	2	\N	{"ubicacion": "sector de reparto de material minera bocamina", "descripcion": "se despacha todo el material de trabajo que se utiliza dia a dia para los socios", "idEncargado": 4, "tipoAlmacen": "SEGURIDAD_INDUSTRIAL", "codigoAlmacen": "ALM-2", "nombreAlmacen": "seguridad industrial", "horarioAtencion": "lunes a viernes 9:00 a 10:00 am", "telefonoContacto": "74758946"}	2026-08-13 20:01:17.067914+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
13	1	Se creó un nuevo registro en Almacenes.	CREAR	Almacenes	almacenes	3	\N	{"ubicacion": "sector transporte", "descripcion": "se despacha y se guarda toda lo que es combustible para posterior reparto a las máquinas de trabajo", "idEncargado": 6, "tipoAlmacen": "COMBUSTIBLE", "codigoAlmacen": "ALM-3", "nombreAlmacen": "combustible", "horarioAtencion": "lunes a viernes de 8:00 a 16:00", "telefonoContacto": "65842595"}	2026-08-13 20:03:59.527353+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
14	1	Se creó un nuevo registro en Proveedores.	CREAR	Proveedores	proveedores	1	\N	{"nit": "1020671027", "rubro": "MATERIAL_EXPLOSIVO_CONTROLADO", "ciudad": "Oruro", "correo": "ventas@carmanltda.com", "telefono": "22434561", "razonSocial": "CARMAR LTDA.", "celularWhatsapp": "74757179", "codigoProveedor": "PROV-1", "nombreComercial": "FAMEXA Explosivos Bolivia", "personaContacto": "bladimir Zapata condori  equipo comercial ventas", "tipoInsumosProvee": "dinamistas, fulminante, masa explosiva, ANFO, etc."}	2026-08-13 20:17:33.245185+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
15	1	Se creó un nuevo registro en Proveedores.	CREAR	Proveedores	proveedores	2	\N	{"nit": "1020473024", "rubro": "COMBUSTIBLE", "ciudad": "Oruro", "correo": "surtidorvinto@gmail.com", "telefono": "25278503", "razonSocial": "PANAMERICANA INTERNACIONAL SRL.", "celularWhatsapp": "63626561", "codigoProveedor": "PROV-2", "nombreComercial": "ESTACION DE SERVICIO VINTO", "personaContacto": "jose mamani mamani encargado de surtidor", "tipoInsumosProvee": "diesel, gasolina especial, gasolina especial (+)"}	2026-08-13 20:23:19.681708+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
16	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	5	\N	{"cargo": "secretario de transporte", "idRol": 4, "correo": "fermin@gmail.com", "estado": "ACTIVO", "idArea": 1, "telefono": "75747695", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "fermin", "nombreCompleto": "fermin condori aguilar", "cedulaIdentidad": "12659858"}	2026-08-13 20:24:08.406848+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
17	1	Se creó un nuevo registro en Proveedores.	CREAR	Proveedores	proveedores	3	\N	{"nit": "1020095027", "rubro": "SEGURIDAD_INDUSTRIAL", "ciudad": "Oruro", "correo": "ventas@agsa.com", "telefono": "2565854956", "razonSocial": "AGENCIAS GENERALES S.A.", "celularWhatsapp": "71840415", "codigoProveedor": "PROV-3", "nombreComercial": "AGSA BOLIVIA", "personaContacto": "Luis Morales Flores encargado de sucursal oruro", "tipoInsumosProvee": "equipos de EEP, cascos, botas de seguridad, guantes, etc."}	2026-08-13 20:29:10.13301+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
18	1	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-08-13 20:33:57.980659+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
19	1	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-08-13 20:47:24.090784+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
20	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	2	\N	{"cargo": "presidente del consejo de vigilancia", "idRol": 3, "correo": "miguel@gmail.com", "estado": "ACTIVO", "idArea": 2, "telefono": "75759535", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "miguel", "nombreCompleto": "miguel tipa lopez", "cedulaIdentidad": "1289654"}	2026-08-13 20:47:56.138274+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
21	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	3	\N	{"cargo": "secretario del area de prevención social (material)", "idRol": 2, "correo": "jose@gmail.com", "estado": "ACTIVO", "idArea": 6, "telefono": "74757677", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "jose", "nombreCompleto": "jose cayoja condori", "cedulaIdentidad": "1263845"}	2026-08-13 20:48:11.82013+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
22	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	4	\N	{"cargo": "secretario de seguridad industrial", "idRol": 2, "correo": "juvenal@gmail.com", "estado": "ACTIVO", "idArea": 6, "telefono": "75747172", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "juve", "nombreCompleto": "juvenal choquecallata villca", "cedulaIdentidad": "1152694"}	2026-08-13 20:48:22.700453+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
23	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	4	\N	{"cargo": "secretario de seguridad industrial", "idRol": 2, "correo": "juvenal@gmail.com", "estado": "ACTIVO", "idArea": 4, "telefono": "75747172", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "juve", "nombreCompleto": "juvenal choquecallata villca", "cedulaIdentidad": "1152694"}	2026-08-13 20:48:38.035853+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
24	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	3	\N	{"cargo": "secretario del area de prevención social (material)", "idRol": 2, "correo": "jose@gmail.com", "estado": "ACTIVO", "idArea": 6, "telefono": "74757677", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "jose", "nombreCompleto": "jose cayoja condori", "cedulaIdentidad": "1263845"}	2026-08-13 20:48:53.135071+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
25	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	5	\N	{"cargo": "secretario de transporte", "idRol": 4, "correo": "fermin@gmail.com", "estado": "ACTIVO", "idArea": 7, "telefono": "75747695", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "fermin", "nombreCompleto": "fermin condori aguilar", "cedulaIdentidad": "12659858"}	2026-08-13 20:49:04.150147+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
26	1	Se actualizó un registro en Usuarios.	EDITAR	Usuarios	usuarios	6	\N	{"cargo": "secretario de combustible minera", "idRol": 2, "correo": "martin@gmail.com", "estado": "ACTIVO", "idArea": 6, "telefono": "64958245", "expedidoCi": "OR", "complementoCi": null, "nombreUsuario": "martin", "nombreCompleto": "martin arocha juntuta", "cedulaIdentidad": "1025869"}	2026-08-13 20:49:34.566178+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
27	1	Se creó un nuevo registro en Insumos.	CREAR	Insumos	insumos	1	\N	{"descripcion": "casco de alta resistencia contra impactos, color cafe, ranurado para orejeras y soporte frontal para lampara minera de calidad 2da", "idCategoria": 2, "stockMinimo": 25, "idTipoInsumo": 11, "nombreInsumo": "casco minero con portalámpara", "codigoInterno": "INS-SI-1", "idUnidadMedida": 1, "precioReferencial": 800}	2026-08-13 21:11:40.528457+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
43	1	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-08-15 12:40:10.174707+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
28	1	Se creó un nuevo registro en Insumos.	CREAR	Insumos	insumos	2	\N	{"descripcion": "Emulsion encartuchada de seguridad, alta resistencia al agua, y baja emisión de gases, proveedor: Carmar Ltda.", "idCategoria": 6, "stockMinimo": 10, "idTipoInsumo": 9, "nombreInsumo": "Dinamita Emulnor 3000", "codigoInterno": "INS-P-1", "idUnidadMedida": 5, "precioReferencial": 420}	2026-08-13 21:15:05.17476+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
29	1	Se creó un nuevo registro en Insumos.	CREAR	Insumos	insumos	3	\N	{"descripcion": "Combustible liquido para maquinaria pesada proveedor: estación de servicio Vinto", "idCategoria": 4, "stockMinimo": 5000, "idTipoInsumo": 9, "nombreInsumo": "Diesel Oil", "codigoInterno": "INS-CU-1", "idUnidadMedida": 3, "precioReferencial": 10}	2026-08-13 21:17:23.630541+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
30	1	Se registro AJUSTE_POSITIVO por 25.	AJUSTAR_INVENTARIO	Inventario y Despachos	movimientos_inventario	1	\N	{"cantidad": 25, "idInsumo": 1, "idAlmacen": 2, "tipoMovimiento": "AJUSTE_POSITIVO"}	2026-08-13 21:27:55.734805+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Regularizacion de stock	se ingresa insumo físico al almacén de seguridad industrial
31	1	Se actualizó un registro en Insumos.	EDITAR	Insumos	insumos	1	\N	{"descripcion": "casco de alta resistencia contra impactos, color cafe, ranurado para orejeras y soporte frontal para lampara minera de calidad 2da", "idCategoria": 2, "stockMinimo": 5, "idTipoInsumo": 11, "nombreInsumo": "casco minero con portalámpara", "codigoInterno": "INS-SI-1", "idUnidadMedida": 1, "precioReferencial": 800}	2026-08-13 21:28:38.189348+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
32	1	Se registro AJUSTE_POSITIVO por 10.	AJUSTAR_INVENTARIO	Inventario y Despachos	movimientos_inventario	2	\N	{"cantidad": 10, "idInsumo": 2, "idAlmacen": 1, "tipoMovimiento": "AJUSTE_POSITIVO"}	2026-08-13 21:30:06.258391+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Regularizacion de stock	se ingresa insumo físico al almacén subterráneo de polvorín
33	1	Se actualizó un registro en Insumos.	EDITAR	Insumos	insumos	2	\N	{"descripcion": "Emulsion encartuchada de seguridad, alta resistencia al agua, y baja emisión de gases, proveedor: Carmar Ltda.", "idCategoria": 6, "stockMinimo": 5, "idTipoInsumo": 9, "nombreInsumo": "Dinamita Emulnor 3000", "codigoInterno": "INS-P-1", "idUnidadMedida": 5, "precioReferencial": 420}	2026-08-13 21:30:21.288936+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
34	1	Se registro AJUSTE_POSITIVO por 5000.	AJUSTAR_INVENTARIO	Inventario y Despachos	movimientos_inventario	3	\N	{"cantidad": 5000, "idInsumo": 3, "idAlmacen": 3, "tipoMovimiento": "AJUSTE_POSITIVO"}	2026-08-13 21:31:14.755955+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Regularizacion de stock	se ingresa insumo físico al almacén de combustibles para maquinaria pesada
35	1	Se actualizó un registro en Insumos.	EDITAR	Insumos	insumos	3	\N	{"descripcion": "Combustible liquido para maquinaria pesada proveedor: estación de servicio Vinto", "idCategoria": 4, "stockMinimo": 500, "idTipoInsumo": 9, "nombreInsumo": "Diesel Oil", "codigoInterno": "INS-CU-1", "idUnidadMedida": 3, "precioReferencial": 10}	2026-08-13 21:31:25.741279+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
36	1	Se creo el pedido PED-0001/2026.	CREAR	Pedidos	pedidos	1	\N	{"detalles": 1, "prioridad": "MEDIA", "estadoPedido": "PENDIENTE", "numeroPedido": "PED-0001/2026", "idAreaSolicitante": 1, "idUsuarioSolicitante": 1}	2026-08-13 21:38:32.27454+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Reposicion por consumo operativo	\N
37	1	Se aprobó el pedido PED-0001/2026.	APROBAR	Pedidos	pedidos	1	{"estadoPedido": "PENDIENTE", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "PENDIENTE"}	{"estadoPedido": "APROBADO", "usuarioRevisa": 1, "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "APROBADO"}	2026-08-13 21:40:35.251341+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	perfecto para el trabajo que se realizara después de la perforación de mañana de 3 horas
38	1	Se envió el pedido PED-0001/2026 a preparación de despacho.	EDITAR	Pedidos	pedidos	1	{"estadoPedido": "APROBADO", "estadoAtencion": "SIN_ATENDER", "estadoAprobacion": "APROBADO"}	{"estadoPedido": "EN_DESPACHO", "estadoAtencion": "EN_PROCESO", "estadoAprobacion": "APROBADO"}	2026-08-13 21:41:21.635888+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
39	1	Se genero el despacho DES-2026-0001.	REALIZAR_DESPACHO	Inventario y Despachos	despachos	1	\N	{"idPedido": 1, "codigoDespacho": "DES-2026-0001", "estadoDespacho": "ENTREGADO_COMPLETO"}	2026-08-13 21:43:33.500413+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	se despacha correctamente el insumo pedido por la cooperativa
40	1	Login correcto de federico	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Login correcto", "resultado": "CORRECTO", "nombreUsuario": "federico"}	2026-08-13 21:51:22.188211+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Login correcto	Inicio de sesiÃ³n exitoso.
41	1	Se actualizó un registro en Notificaciones.	EDITAR	Notificaciones	notificaciones	1	\N	{}	2026-08-13 21:59:59.027218+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	\N	\N
42	1	Login fallido de federico	INICIAR_SESION	Autenticación	usuarios	1	\N	{"motivo": "Contraseña incorrecta", "resultado": "FALLIDO", "nombreUsuario": "federico"}	2026-08-15 12:40:01.464624+00	Localhost (127.0.0.1)	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0	Contraseña incorrecta	Intento de inicio de sesiÃ³n no autorizado.
\.


--
-- Data for Name: categorias_insumo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categorias_insumo (id_categoria, nombre_categoria, descripcion, estado, fecha_creacion, creado_por) FROM stdin;
1	Herramientas y repuestos	Herramientas, piezas y repuestos de apoyo a la operacion mina.	ACTIVO	2026-08-13 20:50:21.321281+00	\N
2	Seguridad industrial	Elementos de proteccion personal y seguridad ocupacional.	ACTIVO	2026-08-13 20:50:21.331706+00	\N
3	Lubricantes	Aceites, grasas y lubricantes para mantenimiento.	ACTIVO	2026-08-13 20:50:21.335645+00	\N
4	Combustible	Combustible utilizado en equipos y operacion.	ACTIVO	2026-08-13 20:50:21.338808+00	\N
5	Material de perforación	Materiales e insumos utilizados en perforacion.	ACTIVO	2026-08-13 20:50:21.341864+00	\N
6	Material explosivo controlado	Material controlado que requiere registro y almacenamiento especial.	ACTIVO	2026-08-13 20:50:21.345299+00	\N
\.


--
-- Data for Name: comprobantes_compra; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.comprobantes_compra (id_comprobante, numero_comprobante, tipo_comprobante, fecha_comprobante, id_proveedor, nit_proveedor, id_orden_compra, monto_subtotal, monto_descuento, moneda, estado_comprobante, archivo_comprobante, observaciones, usuario_registra, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: despacho_detalles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.despacho_detalles (id_despacho_detalle, id_despacho, id_insumo, cantidad_solicitada, cantidad_aprobada, cantidad_entregada, estado_conformidad, observacion) FROM stdin;
1	1	2	2.00	2.00	2.00	CONFORME	que se entrege directamente al presidente de vigilancia
\.


--
-- Data for Name: despachos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.despachos (id_despacho, numero_despacho, id_pedido, id_area_solicitante, id_usuario_solicitante, id_almacen_salida, id_responsable_almacen, persona_recibe, fecha_programada_entrega, fecha_real_entrega, tipo_despacho, estado_despacho, confirmacion_recepcion, evidencia_entrega, observaciones, usuario_registra, fecha_creacion) FROM stdin;
1	DES-2026-0001	1	1	1	1	1	federico choquecallata villca	\N	2026-08-13 21:43:33.35+00	NORMAL	ENTREGADO_COMPLETO	t	\N	se despacha correctamente el insumo pedido por la cooperativa	1	2026-08-13 21:43:33.222625+00
\.


--
-- Data for Name: insumos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.insumos (id_insumo, id_categoria, id_tipo_insumo, id_unidad_medida, id_unidad_medida_secundaria, codigo_interno, codigo_barra_qr, nombre_insumo, descripcion, marca, modelo, presentacion, precio_referencial, stock_minimo, ubicacion_sugerida, requiere_control_especial, es_peligroso_inflamable, fecha_vencimiento, imagen_url, ficha_tecnica_url, estado, observaciones, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
1	2	11	1	\N	INS-SI-1	\N	casco minero con portalámpara	casco de alta resistencia contra impactos, color cafe, ranurado para orejeras y soporte frontal para lampara minera de calidad 2da	\N	\N	\N	800.00	5.00	\N	f	f	\N	\N	\N	ACTIVO	\N	2026-08-13 21:11:40.501719+00	2026-08-13 21:28:38.164+00	\N	\N
2	6	9	5	\N	INS-P-1	\N	Dinamita Emulnor 3000	Emulsion encartuchada de seguridad, alta resistencia al agua, y baja emisión de gases, proveedor: Carmar Ltda.	\N	\N	\N	420.00	5.00	\N	f	f	\N	\N	\N	ACTIVO	\N	2026-08-13 21:15:05.154988+00	2026-08-13 21:30:21.269+00	\N	\N
3	4	9	3	\N	INS-CU-1	\N	Diesel Oil	Combustible liquido para maquinaria pesada proveedor: estación de servicio Vinto	\N	\N	\N	10.00	500.00	\N	f	f	\N	\N	\N	ACTIVO	\N	2026-08-13 21:17:23.612437+00	2026-08-13 21:31:25.713+00	\N	\N
\.


--
-- Data for Name: inventarios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.inventarios (id_inventario, id_insumo, id_almacen, stock_fisico, stock_reservado, costo_promedio, lote, numero_serie, fecha_vencimiento, ubicacion_interna, estado_stock, fecha_ultima_actualizacion, creado_por, actualizado_por) FROM stdin;
1	1	2	25.00	0.00	0.00	\N	\N	\N	\N	DISPONIBLE	2026-08-13 21:27:55.715+00	1	1
3	3	3	5000.00	0.00	0.00	\N	\N	\N	\N	DISPONIBLE	2026-08-13 21:31:14.743+00	1	1
2	2	1	8.00	0.00	0.00	\N	\N	\N	\N	DISPONIBLE	2026-08-13 21:43:33.416+00	1	1
\.


--
-- Data for Name: movimientos_inventario; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.movimientos_inventario (id_movimiento, numero_movimiento, fecha_movimiento, tipo_movimiento, id_insumo, id_almacen_origen, id_almacen_destino, id_despacho, id_recepcion, codigo_referencia, cantidad, costo_unitario, motivo, documento_respaldo, usuario_responsable, observaciones, fecha_creacion) FROM stdin;
1	MOV-AJU-1786656475709	2026-08-13 21:27:55.724+00	AJUSTE_POSITIVO	1	\N	2	\N	\N	AJUSTE MANUAL	25.00	0.00	Regularizacion de stock	\N	1	se ingresa insumo físico al almacén de seguridad industrial	2026-08-13 21:27:55.709222+00
2	MOV-AJU-1786656606239	2026-08-13 21:30:06.25+00	AJUSTE_POSITIVO	2	\N	1	\N	\N	AJUSTE MANUAL	10.00	0.00	Regularizacion de stock	\N	1	se ingresa insumo físico al almacén subterráneo de polvorín	2026-08-13 21:30:06.239976+00
3	MOV-AJU-1786656674737	2026-08-13 21:31:14.746+00	AJUSTE_POSITIVO	3	\N	3	\N	\N	AJUSTE MANUAL	5000.00	0.00	Regularizacion de stock	\N	1	se ingresa insumo físico al almacén de combustibles para maquinaria pesada	2026-08-13 21:31:14.737533+00
4	MOV-DES-1	2026-08-13 21:43:33.222625+00	SALIDA_DESPACHO	2	1	\N	1	\N	DES-2026-0001	2.00	0.00	Salida automática por despacho de insumos	DES-2026-0001	1	Movimiento generado automáticamente desde despacho.	2026-08-13 21:43:33.222625+00
\.


--
-- Data for Name: notificaciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notificaciones (id_notificacion, tipo_notificacion, titulo, mensaje, id_usuario_destinatario, modulo_relacionado, id_registro_relacionado, prioridad, estado_notificacion, fecha_creacion, fecha_lectura, usuario_genera) FROM stdin;
4	PEDIDO_CREADO	Pedido creado	Se registro el pedido PED-0001/2026.	1	Pedidos	1	MEDIA	LEIDA	2026-08-13 21:38:32.290283+00	2026-08-13 21:59:59.02+00	1
5	PEDIDO_APROBADO	Pedido aprobado	El pedido PED-0001/2026 fue aprobado y tiene stock reservado.	1	Pedidos	1	MEDIA	LEIDA	2026-08-13 21:40:35.272121+00	2026-08-13 21:59:59.02+00	1
6	DESPACHO_REALIZADO	Despacho generado	Se genero el despacho DES-2026-0001.	1	Inventario y Despachos	1	MEDIA	LEIDA	2026-08-13 21:43:33.521021+00	2026-08-13 21:59:59.02+00	1
\.


--
-- Data for Name: orden_compra_detalles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.orden_compra_detalles (id_orden_detalle, id_orden_compra, id_insumo, cantidad_solicitada, cantidad_comprada, precio_unitario, observacion) FROM stdin;
\.


--
-- Data for Name: ordenes_compra; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ordenes_compra (id_orden_compra, numero_orden, codigo_correlativo, id_pedido, id_proveedor, fecha_emision, fecha_estimada_entrega, condicion_pago, forma_pago, moneda, estado_pago, subtotal, descuento, estado_compra, observaciones, usuario_genera, fecha_creacion, fecha_actualizacion) FROM stdin;
\.


--
-- Data for Name: pedido_detalles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pedido_detalles (id_pedido_detalle, id_pedido, id_insumo, cantidad_solicitada, cantidad_aprobada, cantidad_despachada, observacion) FROM stdin;
1	1	2	2.00	2.00	2.00	que se entrege directamente al presidente de vigilancia
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pedidos (id_pedido, numero_pedido, id_usuario_solicitante, id_area_solicitante, fecha_pedido, fecha_requerida, tipo_pedido, prioridad, justificacion, estado_pedido, estado_aprobacion, estado_atencion, id_proveedor_sugerido, archivo_adjunto, centro_costo, lugar_uso, turno_guardia, observaciones, id_usuario_revisor, fecha_revision, motivo_rechazo, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
1	PED-0001/2026	1	1	2026-08-13 21:38:32.171+00	2026-08-13 12:00:00+00	NORMAL	MEDIA	Reposicion por consumo operativo	ENTREGADO_COMPLETO	APROBADO	ATENDIDO_TOTAL	\N	\N	\N	interior mina nivel -30 jugar de trabajo paraje de la cooperativa minera	\N	perfecto para el trabajo que se realizara después de la perforación de mañana de 3 horas 	1	2026-08-13 21:40:35.09+00	\N	2026-08-13 21:38:32.172009+00	2026-08-13 21:43:33.426+00	1	1
\.


--
-- Data for Name: permisos; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.permisos (id_permiso, codigo_permiso, modulo, descripcion, fecha_creacion) FROM stdin;
1	dashboard.ver	Dashboard	Ver indicadores del dashboard.	2026-08-05 19:50:07.067152+00
2	usuarios.ver	Usuarios	Ver usuarios.	2026-08-05 19:50:07.067152+00
3	usuarios.crear	Usuarios	Crear usuarios.	2026-08-05 19:50:07.067152+00
4	usuarios.editar	Usuarios	Editar usuarios.	2026-08-05 19:50:07.067152+00
5	usuarios.eliminar	Usuarios	Eliminar usuarios.	2026-08-05 19:50:07.067152+00
6	usuarios.activar	Usuarios	Activar usuarios.	2026-08-05 19:50:07.067152+00
7	usuarios.desactivar	Usuarios	Desactivar usuarios.	2026-08-05 19:50:07.067152+00
8	roles.ver	Usuarios	Ver roles y permisos.	2026-08-05 19:50:07.067152+00
9	roles.editar	Usuarios	Editar roles.	2026-08-05 19:50:07.067152+00
10	auditoria.ver	Auditoria	Ver auditoria.	2026-08-05 19:50:07.067152+00
11	auditoria.detalle	Auditoria	Ver detalle de auditoria.	2026-08-05 19:50:07.067152+00
12	catalogos.ver	Catalogos	Ver catalogos del sistema.	2026-08-05 19:50:07.067152+00
13	almacenes.ver	Almacenes	Ver almacenes.	2026-08-05 19:50:07.067152+00
14	almacenes.crear	Almacenes	Crear almacenes.	2026-08-05 19:50:07.067152+00
15	almacenes.editar	Almacenes	Editar almacenes.	2026-08-05 19:50:07.067152+00
16	almacenes.eliminar	Almacenes	Eliminar almacenes.	2026-08-05 19:50:07.067152+00
17	almacenes.activar	Almacenes	Activar almacenes.	2026-08-05 19:50:07.067152+00
18	almacenes.desactivar	Almacenes	Desactivar almacenes.	2026-08-05 19:50:07.067152+00
19	proveedores.ver	Proveedores	Ver proveedores.	2026-08-05 19:50:07.067152+00
20	proveedores.crear	Proveedores	Crear proveedores.	2026-08-05 19:50:07.067152+00
21	proveedores.editar	Proveedores	Editar proveedores.	2026-08-05 19:50:07.067152+00
22	proveedores.eliminar	Proveedores	Eliminar proveedores.	2026-08-05 19:50:07.067152+00
23	proveedores.activar	Proveedores	Activar proveedores.	2026-08-05 19:50:07.067152+00
24	proveedores.desactivar	Proveedores	Desactivar proveedores.	2026-08-05 19:50:07.067152+00
25	insumos.ver	Insumos	Ver insumos.	2026-08-05 19:50:07.067152+00
26	insumos.crear	Insumos	Crear insumos.	2026-08-05 19:50:07.067152+00
27	insumos.editar	Insumos	Editar insumos.	2026-08-05 19:50:07.067152+00
28	insumos.eliminar	Insumos	Eliminar insumos.	2026-08-05 19:50:07.067152+00
29	insumos.activar	Insumos	Activar insumos.	2026-08-05 19:50:07.067152+00
30	insumos.desactivar	Insumos	Desactivar insumos.	2026-08-05 19:50:07.067152+00
31	inventario.ver	Inventario	Ver inventario.	2026-08-05 19:50:07.067152+00
32	inventario.ajustar	Inventario	Registrar ajustes de inventario.	2026-08-05 19:50:07.067152+00
33	inventario.transferir	Inventario	Registrar transferencias de inventario.	2026-08-05 19:50:07.067152+00
34	inventario.devolver	Inventario	Registrar devoluciones de inventario.	2026-08-05 19:50:07.067152+00
35	inventario.ver_movimientos	Inventario	Ver movimientos de inventario.	2026-08-05 19:50:07.067152+00
36	inventario.ver_stock_critico	Inventario	Ver stock critico.	2026-08-05 19:50:07.067152+00
37	despachos.ver	Despachos	Ver despachos.	2026-08-05 19:50:07.067152+00
38	despachos.crear	Despachos	Crear despachos.	2026-08-05 19:50:07.067152+00
39	despachos.detalle	Despachos	Ver detalle de despachos.	2026-08-05 19:50:07.067152+00
40	pedidos.ver	Pedidos	Ver pedidos.	2026-08-05 19:50:07.067152+00
41	pedidos.crear	Pedidos	Crear pedidos.	2026-08-05 19:50:07.067152+00
42	pedidos.editar	Pedidos	Editar pedidos.	2026-08-05 19:50:07.067152+00
43	pedidos.anular	Pedidos	Anular pedidos.	2026-08-05 19:50:07.067152+00
44	pedidos.aprobar	Pedidos	Aprobar pedidos.	2026-08-05 19:50:07.067152+00
45	pedidos.rechazar	Pedidos	Rechazar pedidos.	2026-08-05 19:50:07.067152+00
46	pedidos.observar	Pedidos	Observar pedidos.	2026-08-05 19:50:07.067152+00
47	pedidos.detalle	Pedidos	Ver detalle de pedidos.	2026-08-05 19:50:07.067152+00
48	compras.ver	Compras	Ver compras.	2026-08-05 19:50:07.067152+00
49	compras.crear_orden	Compras	Crear ordenes de compra.	2026-08-05 19:50:07.067152+00
50	compras.editar_orden	Compras	Editar ordenes de compra.	2026-08-05 19:50:07.067152+00
51	compras.detalle_orden	Compras	Ver detalle de ordenes de compra.	2026-08-05 19:50:07.067152+00
52	recepciones.ver	Recepciones	Ver recepciones.	2026-08-05 19:50:07.067152+00
53	recepciones.crear	Recepciones	Crear recepciones.	2026-08-05 19:50:07.067152+00
54	recepciones.detalle	Recepciones	Ver detalle de recepciones.	2026-08-05 19:50:07.067152+00
55	comprobantes.ver	Comprobantes	Ver comprobantes.	2026-08-05 19:50:07.067152+00
56	comprobantes.crear	Comprobantes	Crear comprobantes.	2026-08-05 19:50:07.067152+00
57	comprobantes.detalle	Comprobantes	Ver detalle de comprobantes.	2026-08-05 19:50:07.067152+00
58	comprobantes.exportar_pdf	Comprobantes	Exportar comprobantes a PDF.	2026-08-05 19:50:07.067152+00
59	reportes.ver	Reportes	Ver reportes.	2026-08-05 19:50:07.067152+00
60	reportes.exportar	Reportes	Exportar reportes.	2026-08-05 19:50:07.067152+00
61	reportes.imprimir	Reportes	Imprimir reportes.	2026-08-05 19:50:07.067152+00
62	notificaciones.ver	Notificaciones	Ver notificaciones.	2026-08-05 19:50:07.067152+00
63	notificaciones.marcar_leida	Notificaciones	Marcar notificaciones como leidas.	2026-08-05 19:50:07.067152+00
64	notificaciones.eliminar	Notificaciones	Eliminar notificaciones.	2026-08-05 19:50:07.067152+00
65	perfil.ver	Perfil	Ver perfil.	2026-08-05 19:50:07.067152+00
66	perfil.editar	Perfil	Editar perfil.	2026-08-05 19:50:07.067152+00
\.


--
-- Data for Name: politicas_stock; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.politicas_stock (id_politica_stock, id_insumo, id_almacen, stock_minimo, stock_maximo, stock_seguridad, estado, fecha_creacion, creado_por) FROM stdin;
\.


--
-- Data for Name: proveedor_insumo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.proveedor_insumo (id_proveedor, id_insumo, precio_referencial, tiempo_entrega_dias, estado) FROM stdin;
\.


--
-- Data for Name: proveedores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.proveedores (id_proveedor, codigo_proveedor, razon_social, nombre_comercial, nit, rubro, tipo_insumos_provee, persona_contacto, cargo_contacto, telefono, celular_whatsapp, correo, direccion, ciudad, condiciones_pago, forma_pago, tiempo_estimado_entrega, calificacion, documentacion_vigente, estado, observaciones, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
1	PROV-1	CARMAR LTDA.	FAMEXA Explosivos Bolivia	1020671027	MATERIAL_EXPLOSIVO_CONTROLADO	dinamistas, fulminante, masa explosiva, ANFO, etc.	bladimir Zapata condori  equipo comercial ventas	\N	22434561	74757179	ventas@carmanltda.com	\N	Oruro	\N	\N	\N	\N	t	ACTIVO	\N	2026-08-13 20:17:33.233262+00	\N	\N	\N
2	PROV-2	PANAMERICANA INTERNACIONAL SRL.	ESTACION DE SERVICIO VINTO	1020473024	COMBUSTIBLE	diesel, gasolina especial, gasolina especial (+)	jose mamani mamani encargado de surtidor	\N	25278503	63626561	surtidorvinto@gmail.com	\N	Oruro	\N	\N	\N	\N	t	ACTIVO	\N	2026-08-13 20:23:19.670587+00	\N	\N	\N
3	PROV-3	AGENCIAS GENERALES S.A.	AGSA BOLIVIA	1020095027	SEGURIDAD_INDUSTRIAL	equipos de EEP, cascos, botas de seguridad, guantes, etc.	Luis Morales Flores encargado de sucursal oruro	\N	2565854956	71840415	ventas@agsa.com	\N	Oruro	\N	\N	\N	\N	t	ACTIVO	\N	2026-08-13 20:29:10.123859+00	\N	\N	\N
\.


--
-- Data for Name: recepcion_detalles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.recepcion_detalles (id_recepcion_detalle, id_recepcion, id_orden_detalle, id_insumo, cantidad_comprada, cantidad_recibida, cantidad_aceptada, cantidad_rechazada, cantidad_faltante, motivo_rechazo, estado_conformidad, observaciones) FROM stdin;
\.


--
-- Data for Name: recepciones_compra; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.recepciones_compra (id_recepcion, numero_recepcion, id_orden_compra, id_proveedor, id_almacen_destino, fecha_estimada_recepcion, fecha_real_recepcion, id_responsable_recepcion, estado_recepcion, documento_respaldo, observaciones, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: reservas_stock; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.reservas_stock (id_reserva_stock, id_inventario, id_insumo, id_almacen, id_pedido, id_pedido_detalle, cantidad_reservada, estado, fecha_reserva, fecha_liberacion) FROM stdin;
1	2	2	1	1	1	0.00	LIBERADA	2026-08-13 21:40:35.08015+00	2026-08-13 21:43:33.422+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id_rol, nombre_rol, descripcion, estado, fecha_creacion, fecha_actualizacion) FROM stdin;
1	Administrador del sistema	Acceso total al sistema, usuarios, seguridad, reportes y auditoria.	ACTIVO	2026-08-05 19:50:07.067152+00	2026-08-15 12:40:15.091+00
2	Encargado de almacén	Responsable operativo de almacenes, inventario, movimientos y despachos.	ACTIVO	2026-08-05 19:50:07.067152+00	2026-08-15 12:40:15.113+00
3	Supervisor de mina	Solicita insumos para operación minera y realiza seguimiento a pedidos.	ACTIVO	2026-08-05 19:50:07.067152+00	2026-08-15 12:40:15.122+00
4	Jefe de área	Responsable de revisar, aprobar, observar o rechazar pedidos del área.	ACTIVO	2026-08-05 19:50:07.067152+00	2026-08-15 12:40:15.13+00
5	Encargado de compras	Responsable de proveedores, compras, recepciones y comprobantes.	ACTIVO	2026-08-05 19:50:07.067152+00	2026-08-15 12:40:15.139+00
6	Auditor	Usuario con acceso de consulta a auditoría, trazabilidad y reportes.	ACTIVO	2026-08-05 19:50:07.067152+00	2026-08-15 12:40:15.145+00
7	Usuario solicitante	Usuario que crea pedidos de insumos y realiza seguimiento a sus solicitudes.	ACTIVO	2026-08-05 19:50:07.067152+00	2026-08-15 12:40:15.152+00
\.


--
-- Data for Name: roles_permisos; Type: TABLE DATA; Schema: public; Owner: -
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
1	21
1	22
1	23
1	24
1	25
1	26
1	27
1	28
1	29
1	30
1	31
1	32
1	33
1	34
1	35
1	36
1	37
1	38
1	39
1	40
1	41
1	42
1	43
1	44
1	45
1	46
1	47
1	48
1	49
1	50
1	51
1	52
1	53
1	54
1	55
1	56
1	57
1	58
1	59
1	60
1	61
1	62
1	63
1	64
1	65
1	66
\.


--
-- Data for Name: tipos_insumo; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tipos_insumo (id_tipo_insumo, nombre_tipo, descripcion, estado, fecha_creacion, creado_por) FROM stdin;
1	Consumible	Insumo que se consume durante la operacion.	ACTIVO	2026-08-13 20:50:21.352431+00	\N
2	Herramienta	Herramienta de uso operativo.	ACTIVO	2026-08-13 20:50:21.356856+00	\N
3	Repuesto	Repuesto de equipos o maquinaria.	ACTIVO	2026-08-13 20:50:21.3602+00	\N
4	Material de seguridad	Insumo relacionado con seguridad industrial.	ACTIVO	2026-08-13 20:50:21.36501+00	\N
5	Combustible	Insumo combustible.	ACTIVO	2026-08-13 20:50:21.367873+00	\N
6	Material controlado	Insumo que requiere control especial.	ACTIVO	2026-08-13 20:50:21.371023+00	\N
7	Consumible operativo	Insumo que se consume durante la operacion diaria.	ACTIVO	2026-08-13 21:05:48.989471+00	\N
8	Herramienta devolutiva	Herramienta que debe devolverse despues de su uso.	ACTIVO	2026-08-13 21:05:49.005218+00	\N
9	Material fiscalizado	Material sujeto a control y fiscalizacion.	ACTIVO	2026-08-13 21:05:49.009507+00	\N
10	Repuesto/componente	Repuesto o componente de equipos y maquinaria.	ACTIVO	2026-08-13 21:05:49.013818+00	\N
11	EPP desechable	Equipo de proteccion personal de uso desechable.	ACTIVO	2026-08-13 21:05:49.018448+00	\N
\.


--
-- Data for Name: unidades_medida; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.unidades_medida (id_unidad_medida, nombre_unidad, abreviatura, descripcion, estado, fecha_creacion) FROM stdin;
1	Unidad	unid	Unidad individual.	ACTIVO	2026-08-13 20:50:21.378953+00
2	Par	par	Par de elementos.	ACTIVO	2026-08-13 20:50:21.385207+00
3	Litro	L	Medida de volumen en litros.	ACTIVO	2026-08-13 20:50:21.388516+00
4	Kilogramo	kg	Medida de peso en kilogramos.	ACTIVO	2026-08-13 20:50:21.391843+00
5	Caja	caja	Presentacion por caja.	ACTIVO	2026-08-13 20:50:21.395859+00
6	Metro	m	Medida de longitud en metros.	ACTIVO	2026-08-13 20:50:21.399972+00
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuarios (id_usuario, id_area, id_rol, nombre_completo, nombre_usuario, correo, cedula_identidad, complemento_ci, expedido_ci, password_hash, telefono, cargo, estado, ultimo_inicio_sesion, intentos_fallidos, cambio_obligatorio, fecha_creacion, fecha_actualizacion, creado_por, actualizado_por) FROM stdin;
2	2	3	miguel tipa lopez	miguel	miguel@gmail.com	1289654	\N	OR	$2b$10$Jf/lcgtDELp/M8mXVgEm6ORqLpjMy7s21nz.aZLRuV4HQacV5qQoC	75759535	presidente del consejo de vigilancia	ACTIVO	\N	0	f	2026-08-13 19:18:22.496194+00	2026-08-13 20:47:56.114+00	\N	\N
4	4	2	juvenal choquecallata villca	juve	juvenal@gmail.com	1152694	\N	OR	$2b$10$iLfQP7KXLPlZLglCS7ren.RYVh632okLpJVKiRy1XaoQyB6iJZUWu	75747172	secretario de seguridad industrial	ACTIVO	\N	0	f	2026-08-13 19:40:25.2821+00	2026-08-13 20:48:38.016+00	\N	\N
3	6	2	jose cayoja condori	jose	jose@gmail.com	1263845	\N	OR	$2b$10$aZ0abi0R/WQZhBlzu4CN7.9.T95qLTz1q0pJt866GoQq72.JqYB/.	74757677	secretario del area de prevención social (material)	ACTIVO	\N	0	f	2026-08-13 19:31:13.729471+00	2026-08-13 20:48:53.116+00	\N	\N
5	7	4	fermin condori aguilar	fermin	fermin@gmail.com	12659858	\N	OR	$2b$10$VN0szSs41gYvRnJNb4kibOcGW75iCHJXBfRCTg1uLWDLEH6r/D58m	75747695	secretario de transporte	ACTIVO	\N	0	f	2026-08-13 19:43:05.198857+00	2026-08-13 20:49:04.131+00	\N	\N
6	6	2	martin arocha juntuta	martin	martin@gmail.com	1025869	\N	OR	$2b$10$ozrU9GkdnbzouT8I0pLJDeWoUZF.oEtN95dcPdGUfpSxoEOEuRbyS	64958245	secretario de combustible minera	ACTIVO	\N	0	f	2026-08-13 19:45:13.294413+00	2026-08-13 20:49:34.547+00	\N	\N
1	1	1	federico choquecallata villca	federico	feyckon@gmail.com	12901305	\N	OR	$2b$10$GgdiHI4w3VT.ZUWQZCyWx.1vCXIlRKPeL76SvnYgrSDKA12MncroC	74477014	presidente de la cooperativa minera el porvenir R.L.	ACTIVO	2026-08-15 12:40:10.133+00	0	f	2026-08-05 19:50:07.067152+00	2026-08-15 12:40:10.133+00	\N	\N
\.


--
-- Name: almacenes_id_almacen_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.almacenes_id_almacen_seq', 3, true);


--
-- Name: aprobaciones_pedido_id_aprobacion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.aprobaciones_pedido_id_aprobacion_seq', 1, false);


--
-- Name: areas_id_area_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.areas_id_area_seq', 11, true);


--
-- Name: auditorias_id_auditoria_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.auditorias_id_auditoria_seq', 43, true);


--
-- Name: categorias_insumo_id_categoria_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categorias_insumo_id_categoria_seq', 6, true);


--
-- Name: comprobantes_compra_id_comprobante_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comprobantes_compra_id_comprobante_seq', 1, false);


--
-- Name: despacho_detalles_id_despacho_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.despacho_detalles_id_despacho_detalle_seq', 1, true);


--
-- Name: despachos_id_despacho_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.despachos_id_despacho_seq', 1, true);


--
-- Name: insumos_id_insumo_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.insumos_id_insumo_seq', 3, true);


--
-- Name: inventarios_id_inventario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.inventarios_id_inventario_seq', 3, true);


--
-- Name: movimientos_inventario_id_movimiento_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.movimientos_inventario_id_movimiento_seq', 4, true);


--
-- Name: notificaciones_id_notificacion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notificaciones_id_notificacion_seq', 6, true);


--
-- Name: orden_compra_detalles_id_orden_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.orden_compra_detalles_id_orden_detalle_seq', 1, false);


--
-- Name: ordenes_compra_id_orden_compra_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ordenes_compra_id_orden_compra_seq', 1, false);


--
-- Name: pedido_detalles_id_pedido_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pedido_detalles_id_pedido_detalle_seq', 1, true);


--
-- Name: pedidos_id_pedido_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.pedidos_id_pedido_seq', 1, true);


--
-- Name: permisos_id_permiso_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.permisos_id_permiso_seq', 66, true);


--
-- Name: politicas_stock_id_politica_stock_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.politicas_stock_id_politica_stock_seq', 1, false);


--
-- Name: proveedores_id_proveedor_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.proveedores_id_proveedor_seq', 3, true);


--
-- Name: recepcion_detalles_id_recepcion_detalle_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recepcion_detalles_id_recepcion_detalle_seq', 1, false);


--
-- Name: recepciones_compra_id_recepcion_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recepciones_compra_id_recepcion_seq', 1, false);


--
-- Name: reservas_stock_id_reserva_stock_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reservas_stock_id_reserva_stock_seq', 1, true);


--
-- Name: roles_id_rol_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_id_rol_seq', 7, true);


--
-- Name: tipos_insumo_id_tipo_insumo_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_insumo_id_tipo_insumo_seq', 11, true);


--
-- Name: unidades_medida_id_unidad_medida_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.unidades_medida_id_unidad_medida_seq', 6, true);


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.usuarios_id_usuario_seq', 6, true);


--
-- Name: almacenes almacenes_codigo_almacen_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_codigo_almacen_key UNIQUE (codigo_almacen);


--
-- Name: almacenes almacenes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_pkey PRIMARY KEY (id_almacen);


--
-- Name: aprobaciones_pedido aprobaciones_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aprobaciones_pedido
    ADD CONSTRAINT aprobaciones_pedido_pkey PRIMARY KEY (id_aprobacion);


--
-- Name: areas areas_nombre_area_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_nombre_area_key UNIQUE (nombre_area);


--
-- Name: areas areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id_area);


--
-- Name: auditorias auditorias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditorias
    ADD CONSTRAINT auditorias_pkey PRIMARY KEY (id_auditoria);


--
-- Name: categorias_insumo categorias_insumo_nombre_categoria_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias_insumo
    ADD CONSTRAINT categorias_insumo_nombre_categoria_key UNIQUE (nombre_categoria);


--
-- Name: categorias_insumo categorias_insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias_insumo
    ADD CONSTRAINT categorias_insumo_pkey PRIMARY KEY (id_categoria);


--
-- Name: comprobantes_compra comprobantes_compra_numero_comprobante_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_numero_comprobante_key UNIQUE (numero_comprobante);


--
-- Name: comprobantes_compra comprobantes_compra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_pkey PRIMARY KEY (id_comprobante);


--
-- Name: despacho_detalles despacho_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despacho_detalles
    ADD CONSTRAINT despacho_detalles_pkey PRIMARY KEY (id_despacho_detalle);


--
-- Name: despachos despachos_numero_despacho_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_numero_despacho_key UNIQUE (numero_despacho);


--
-- Name: despachos despachos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_pkey PRIMARY KEY (id_despacho);


--
-- Name: insumos insumos_codigo_barra_qr_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_codigo_barra_qr_key UNIQUE (codigo_barra_qr);


--
-- Name: insumos insumos_codigo_interno_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_codigo_interno_key UNIQUE (codigo_interno);


--
-- Name: insumos insumos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_pkey PRIMARY KEY (id_insumo);


--
-- Name: inventarios inventarios_id_insumo_id_almacen_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_insumo_id_almacen_key UNIQUE (id_insumo, id_almacen);


--
-- Name: inventarios inventarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_pkey PRIMARY KEY (id_inventario);


--
-- Name: movimientos_inventario movimientos_inventario_numero_movimiento_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_numero_movimiento_key UNIQUE (numero_movimiento);


--
-- Name: movimientos_inventario movimientos_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_pkey PRIMARY KEY (id_movimiento);


--
-- Name: notificaciones notificaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_pkey PRIMARY KEY (id_notificacion);


--
-- Name: orden_compra_detalles orden_compra_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orden_compra_detalles
    ADD CONSTRAINT orden_compra_detalles_pkey PRIMARY KEY (id_orden_detalle);


--
-- Name: ordenes_compra ordenes_compra_codigo_correlativo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_codigo_correlativo_key UNIQUE (codigo_correlativo);


--
-- Name: ordenes_compra ordenes_compra_numero_orden_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_numero_orden_key UNIQUE (numero_orden);


--
-- Name: ordenes_compra ordenes_compra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_pkey PRIMARY KEY (id_orden_compra);


--
-- Name: pedido_detalles pedido_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_detalles
    ADD CONSTRAINT pedido_detalles_pkey PRIMARY KEY (id_pedido_detalle);


--
-- Name: pedidos pedidos_numero_pedido_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_numero_pedido_key UNIQUE (numero_pedido);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id_pedido);


--
-- Name: permisos permisos_codigo_permiso_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_codigo_permiso_key UNIQUE (codigo_permiso);


--
-- Name: permisos permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT permisos_pkey PRIMARY KEY (id_permiso);


--
-- Name: politicas_stock politicas_stock_id_insumo_id_almacen_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_id_insumo_id_almacen_key UNIQUE (id_insumo, id_almacen);


--
-- Name: politicas_stock politicas_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_pkey PRIMARY KEY (id_politica_stock);


--
-- Name: proveedor_insumo proveedor_insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedor_insumo
    ADD CONSTRAINT proveedor_insumo_pkey PRIMARY KEY (id_proveedor, id_insumo);


--
-- Name: proveedores proveedores_codigo_proveedor_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_codigo_proveedor_key UNIQUE (codigo_proveedor);


--
-- Name: proveedores proveedores_nit_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_nit_key UNIQUE (nit);


--
-- Name: proveedores proveedores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_pkey PRIMARY KEY (id_proveedor);


--
-- Name: recepcion_detalles recepcion_detalles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepcion_detalles
    ADD CONSTRAINT recepcion_detalles_pkey PRIMARY KEY (id_recepcion_detalle);


--
-- Name: recepciones_compra recepciones_compra_numero_recepcion_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_numero_recepcion_key UNIQUE (numero_recepcion);


--
-- Name: recepciones_compra recepciones_compra_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_pkey PRIMARY KEY (id_recepcion);


--
-- Name: reservas_stock reservas_stock_id_pedido_detalle_id_almacen_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_pedido_detalle_id_almacen_key UNIQUE (id_pedido_detalle, id_almacen);


--
-- Name: reservas_stock reservas_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_pkey PRIMARY KEY (id_reserva_stock);


--
-- Name: roles roles_nombre_rol_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_nombre_rol_key UNIQUE (nombre_rol);


--
-- Name: roles_permisos roles_permisos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_pkey PRIMARY KEY (id_rol, id_permiso);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_rol);


--
-- Name: tipos_insumo tipos_insumo_nombre_tipo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_insumo
    ADD CONSTRAINT tipos_insumo_nombre_tipo_key UNIQUE (nombre_tipo);


--
-- Name: tipos_insumo tipos_insumo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_insumo
    ADD CONSTRAINT tipos_insumo_pkey PRIMARY KEY (id_tipo_insumo);


--
-- Name: unidades_medida unidades_medida_abreviatura_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidades_medida
    ADD CONSTRAINT unidades_medida_abreviatura_key UNIQUE (abreviatura);


--
-- Name: unidades_medida unidades_medida_nombre_unidad_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidades_medida
    ADD CONSTRAINT unidades_medida_nombre_unidad_key UNIQUE (nombre_unidad);


--
-- Name: unidades_medida unidades_medida_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unidades_medida
    ADD CONSTRAINT unidades_medida_pkey PRIMARY KEY (id_unidad_medida);


--
-- Name: usuarios usuarios_correo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);


--
-- Name: usuarios usuarios_nombre_usuario_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_nombre_usuario_key UNIQUE (nombre_usuario);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: idx_almacenes_estado_no_eliminado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_almacenes_estado_no_eliminado ON public.almacenes USING btree (estado) WHERE ((estado)::text <> 'ELIMINADO'::text);


--
-- Name: idx_auditorias_usuario_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditorias_usuario_fecha ON public.auditorias USING btree (id_usuario, fecha_hora);


--
-- Name: idx_despachos_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_despachos_pedido ON public.despachos USING btree (id_pedido);


--
-- Name: idx_insumos_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_insumos_categoria ON public.insumos USING btree (id_categoria);


--
-- Name: idx_insumos_estado_no_eliminado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_insumos_estado_no_eliminado ON public.insumos USING btree (estado) WHERE ((estado)::text <> 'ELIMINADO'::text);


--
-- Name: idx_insumos_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_insumos_tipo ON public.insumos USING btree (id_tipo_insumo);


--
-- Name: idx_inventarios_almacen; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventarios_almacen ON public.inventarios USING btree (id_almacen);


--
-- Name: idx_inventarios_insumo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventarios_insumo ON public.inventarios USING btree (id_insumo);


--
-- Name: idx_movimientos_codigo_referencia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movimientos_codigo_referencia ON public.movimientos_inventario USING btree (codigo_referencia);


--
-- Name: idx_movimientos_id_despacho; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movimientos_id_despacho ON public.movimientos_inventario USING btree (id_despacho);


--
-- Name: idx_movimientos_id_recepcion; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movimientos_id_recepcion ON public.movimientos_inventario USING btree (id_recepcion);


--
-- Name: idx_movimientos_insumo_fecha; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_movimientos_insumo_fecha ON public.movimientos_inventario USING btree (id_insumo, fecha_movimiento);


--
-- Name: idx_notificaciones_usuario_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notificaciones_usuario_estado ON public.notificaciones USING btree (id_usuario_destinatario, estado_notificacion);


--
-- Name: idx_ordenes_proveedor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ordenes_proveedor ON public.ordenes_compra USING btree (id_proveedor);


--
-- Name: idx_pedidos_area; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_area ON public.pedidos USING btree (id_area_solicitante);


--
-- Name: idx_pedidos_estado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_estado ON public.pedidos USING btree (estado_pedido);


--
-- Name: idx_proveedores_estado_no_eliminado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_proveedores_estado_no_eliminado ON public.proveedores USING btree (estado) WHERE ((estado)::text <> 'ELIMINADO'::text);


--
-- Name: idx_usuarios_area; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_area ON public.usuarios USING btree (id_area);


--
-- Name: idx_usuarios_estado_no_eliminado; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_estado_no_eliminado ON public.usuarios USING btree (estado) WHERE ((estado)::text <> 'ELIMINADO'::text);


--
-- Name: idx_usuarios_rol; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_rol ON public.usuarios USING btree (id_rol);


--
-- Name: ux_usuarios_cedula_identidad; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_usuarios_cedula_identidad ON public.usuarios USING btree (cedula_identidad) WHERE ((cedula_identidad IS NOT NULL) AND (btrim((cedula_identidad)::text) <> ''::text));


--
-- Name: despacho_detalles trg_despacho_actualiza_inventario; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_despacho_actualiza_inventario AFTER INSERT ON public.despacho_detalles FOR EACH ROW EXECUTE FUNCTION public.fn_despacho_actualiza_inventario();


--
-- Name: recepcion_detalles trg_recepcion_actualiza_inventario; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_recepcion_actualiza_inventario AFTER INSERT ON public.recepcion_detalles FOR EACH ROW EXECUTE FUNCTION public.fn_recepcion_actualiza_inventario();


--
-- Name: almacenes almacenes_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: almacenes almacenes_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: almacenes almacenes_id_responsable_principal_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_id_responsable_principal_fkey FOREIGN KEY (id_responsable_principal) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: almacenes almacenes_id_responsable_suplente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.almacenes
    ADD CONSTRAINT almacenes_id_responsable_suplente_fkey FOREIGN KEY (id_responsable_suplente) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: aprobaciones_pedido aprobaciones_pedido_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aprobaciones_pedido
    ADD CONSTRAINT aprobaciones_pedido_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido) ON DELETE CASCADE;


--
-- Name: aprobaciones_pedido aprobaciones_pedido_id_usuario_aprobador_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.aprobaciones_pedido
    ADD CONSTRAINT aprobaciones_pedido_id_usuario_aprobador_fkey FOREIGN KEY (id_usuario_aprobador) REFERENCES public.usuarios(id_usuario);


--
-- Name: auditorias auditorias_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditorias
    ADD CONSTRAINT auditorias_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: categorias_insumo categorias_insumo_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias_insumo
    ADD CONSTRAINT categorias_insumo_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: comprobantes_compra comprobantes_compra_id_orden_compra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_id_orden_compra_fkey FOREIGN KEY (id_orden_compra) REFERENCES public.ordenes_compra(id_orden_compra);


--
-- Name: comprobantes_compra comprobantes_compra_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor);


--
-- Name: comprobantes_compra comprobantes_compra_usuario_registra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprobantes_compra
    ADD CONSTRAINT comprobantes_compra_usuario_registra_fkey FOREIGN KEY (usuario_registra) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: despacho_detalles despacho_detalles_id_despacho_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despacho_detalles
    ADD CONSTRAINT despacho_detalles_id_despacho_fkey FOREIGN KEY (id_despacho) REFERENCES public.despachos(id_despacho) ON DELETE CASCADE;


--
-- Name: despacho_detalles despacho_detalles_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despacho_detalles
    ADD CONSTRAINT despacho_detalles_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: despachos despachos_id_almacen_salida_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_almacen_salida_fkey FOREIGN KEY (id_almacen_salida) REFERENCES public.almacenes(id_almacen);


--
-- Name: despachos despachos_id_area_solicitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_area_solicitante_fkey FOREIGN KEY (id_area_solicitante) REFERENCES public.areas(id_area);


--
-- Name: despachos despachos_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido);


--
-- Name: despachos despachos_id_responsable_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_responsable_almacen_fkey FOREIGN KEY (id_responsable_almacen) REFERENCES public.usuarios(id_usuario);


--
-- Name: despachos despachos_id_usuario_solicitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_id_usuario_solicitante_fkey FOREIGN KEY (id_usuario_solicitante) REFERENCES public.usuarios(id_usuario);


--
-- Name: despachos despachos_usuario_registra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despachos
    ADD CONSTRAINT despachos_usuario_registra_fkey FOREIGN KEY (usuario_registra) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: insumos insumos_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: insumos insumos_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: insumos insumos_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categorias_insumo(id_categoria);


--
-- Name: insumos insumos_id_tipo_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_id_tipo_insumo_fkey FOREIGN KEY (id_tipo_insumo) REFERENCES public.tipos_insumo(id_tipo_insumo);


--
-- Name: insumos insumos_id_unidad_medida_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_id_unidad_medida_fkey FOREIGN KEY (id_unidad_medida) REFERENCES public.unidades_medida(id_unidad_medida);


--
-- Name: insumos insumos_id_unidad_medida_secundaria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.insumos
    ADD CONSTRAINT insumos_id_unidad_medida_secundaria_fkey FOREIGN KEY (id_unidad_medida_secundaria) REFERENCES public.unidades_medida(id_unidad_medida);


--
-- Name: inventarios inventarios_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: inventarios inventarios_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: inventarios inventarios_id_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_almacen_fkey FOREIGN KEY (id_almacen) REFERENCES public.almacenes(id_almacen);


--
-- Name: inventarios inventarios_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: movimientos_inventario movimientos_inventario_id_almacen_destino_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_almacen_destino_fkey FOREIGN KEY (id_almacen_destino) REFERENCES public.almacenes(id_almacen);


--
-- Name: movimientos_inventario movimientos_inventario_id_almacen_origen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_almacen_origen_fkey FOREIGN KEY (id_almacen_origen) REFERENCES public.almacenes(id_almacen);


--
-- Name: movimientos_inventario movimientos_inventario_id_despacho_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_despacho_fkey FOREIGN KEY (id_despacho) REFERENCES public.despachos(id_despacho) ON DELETE SET NULL;


--
-- Name: movimientos_inventario movimientos_inventario_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: movimientos_inventario movimientos_inventario_id_recepcion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_id_recepcion_fkey FOREIGN KEY (id_recepcion) REFERENCES public.recepciones_compra(id_recepcion) ON DELETE SET NULL;


--
-- Name: movimientos_inventario movimientos_inventario_usuario_responsable_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movimientos_inventario
    ADD CONSTRAINT movimientos_inventario_usuario_responsable_fkey FOREIGN KEY (usuario_responsable) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: notificaciones notificaciones_id_usuario_destinatario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_id_usuario_destinatario_fkey FOREIGN KEY (id_usuario_destinatario) REFERENCES public.usuarios(id_usuario) ON DELETE CASCADE;


--
-- Name: notificaciones notificaciones_usuario_genera_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notificaciones
    ADD CONSTRAINT notificaciones_usuario_genera_fkey FOREIGN KEY (usuario_genera) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: orden_compra_detalles orden_compra_detalles_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orden_compra_detalles
    ADD CONSTRAINT orden_compra_detalles_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: orden_compra_detalles orden_compra_detalles_id_orden_compra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orden_compra_detalles
    ADD CONSTRAINT orden_compra_detalles_id_orden_compra_fkey FOREIGN KEY (id_orden_compra) REFERENCES public.ordenes_compra(id_orden_compra) ON DELETE CASCADE;


--
-- Name: ordenes_compra ordenes_compra_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido);


--
-- Name: ordenes_compra ordenes_compra_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor);


--
-- Name: ordenes_compra ordenes_compra_usuario_genera_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ordenes_compra
    ADD CONSTRAINT ordenes_compra_usuario_genera_fkey FOREIGN KEY (usuario_genera) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: pedido_detalles pedido_detalles_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_detalles
    ADD CONSTRAINT pedido_detalles_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: pedido_detalles pedido_detalles_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedido_detalles
    ADD CONSTRAINT pedido_detalles_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido) ON DELETE CASCADE;


--
-- Name: pedidos pedidos_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: pedidos pedidos_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: pedidos pedidos_id_area_solicitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_area_solicitante_fkey FOREIGN KEY (id_area_solicitante) REFERENCES public.areas(id_area);


--
-- Name: pedidos pedidos_id_proveedor_sugerido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_proveedor_sugerido_fkey FOREIGN KEY (id_proveedor_sugerido) REFERENCES public.proveedores(id_proveedor);


--
-- Name: pedidos pedidos_id_usuario_revisor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_usuario_revisor_fkey FOREIGN KEY (id_usuario_revisor) REFERENCES public.usuarios(id_usuario);


--
-- Name: pedidos pedidos_id_usuario_solicitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_usuario_solicitante_fkey FOREIGN KEY (id_usuario_solicitante) REFERENCES public.usuarios(id_usuario);


--
-- Name: politicas_stock politicas_stock_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: politicas_stock politicas_stock_id_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_id_almacen_fkey FOREIGN KEY (id_almacen) REFERENCES public.almacenes(id_almacen) ON DELETE CASCADE;


--
-- Name: politicas_stock politicas_stock_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.politicas_stock
    ADD CONSTRAINT politicas_stock_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo) ON DELETE CASCADE;


--
-- Name: proveedor_insumo proveedor_insumo_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedor_insumo
    ADD CONSTRAINT proveedor_insumo_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo) ON DELETE CASCADE;


--
-- Name: proveedor_insumo proveedor_insumo_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedor_insumo
    ADD CONSTRAINT proveedor_insumo_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor) ON DELETE CASCADE;


--
-- Name: proveedores proveedores_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: proveedores proveedores_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.proveedores
    ADD CONSTRAINT proveedores_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: recepcion_detalles recepcion_detalles_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepcion_detalles
    ADD CONSTRAINT recepcion_detalles_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: recepcion_detalles recepcion_detalles_id_orden_detalle_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepcion_detalles
    ADD CONSTRAINT recepcion_detalles_id_orden_detalle_fkey FOREIGN KEY (id_orden_detalle) REFERENCES public.orden_compra_detalles(id_orden_detalle);


--
-- Name: recepcion_detalles recepcion_detalles_id_recepcion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepcion_detalles
    ADD CONSTRAINT recepcion_detalles_id_recepcion_fkey FOREIGN KEY (id_recepcion) REFERENCES public.recepciones_compra(id_recepcion) ON DELETE CASCADE;


--
-- Name: recepciones_compra recepciones_compra_id_almacen_destino_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_id_almacen_destino_fkey FOREIGN KEY (id_almacen_destino) REFERENCES public.almacenes(id_almacen);


--
-- Name: recepciones_compra recepciones_compra_id_orden_compra_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_id_orden_compra_fkey FOREIGN KEY (id_orden_compra) REFERENCES public.ordenes_compra(id_orden_compra);


--
-- Name: recepciones_compra recepciones_compra_id_proveedor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_id_proveedor_fkey FOREIGN KEY (id_proveedor) REFERENCES public.proveedores(id_proveedor);


--
-- Name: recepciones_compra recepciones_compra_id_responsable_recepcion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recepciones_compra
    ADD CONSTRAINT recepciones_compra_id_responsable_recepcion_fkey FOREIGN KEY (id_responsable_recepcion) REFERENCES public.usuarios(id_usuario);


--
-- Name: reservas_stock reservas_stock_id_almacen_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_almacen_fkey FOREIGN KEY (id_almacen) REFERENCES public.almacenes(id_almacen);


--
-- Name: reservas_stock reservas_stock_id_insumo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_insumo_fkey FOREIGN KEY (id_insumo) REFERENCES public.insumos(id_insumo);


--
-- Name: reservas_stock reservas_stock_id_inventario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_inventario_fkey FOREIGN KEY (id_inventario) REFERENCES public.inventarios(id_inventario) ON DELETE CASCADE;


--
-- Name: reservas_stock reservas_stock_id_pedido_detalle_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_pedido_detalle_fkey FOREIGN KEY (id_pedido_detalle) REFERENCES public.pedido_detalles(id_pedido_detalle) ON DELETE CASCADE;


--
-- Name: reservas_stock reservas_stock_id_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservas_stock
    ADD CONSTRAINT reservas_stock_id_pedido_fkey FOREIGN KEY (id_pedido) REFERENCES public.pedidos(id_pedido) ON DELETE CASCADE;


--
-- Name: roles_permisos roles_permisos_id_permiso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_id_permiso_fkey FOREIGN KEY (id_permiso) REFERENCES public.permisos(id_permiso) ON DELETE CASCADE;


--
-- Name: roles_permisos roles_permisos_id_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles_permisos
    ADD CONSTRAINT roles_permisos_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol) ON DELETE CASCADE;


--
-- Name: tipos_insumo tipos_insumo_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_insumo
    ADD CONSTRAINT tipos_insumo_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: usuarios usuarios_actualizado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_actualizado_por_fkey FOREIGN KEY (actualizado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: usuarios usuarios_creado_por_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES public.usuarios(id_usuario) ON DELETE SET NULL;


--
-- Name: usuarios usuarios_id_area_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_id_area_fkey FOREIGN KEY (id_area) REFERENCES public.areas(id_area);


--
-- Name: usuarios usuarios_id_rol_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol);


--
-- PostgreSQL database dump complete
--



