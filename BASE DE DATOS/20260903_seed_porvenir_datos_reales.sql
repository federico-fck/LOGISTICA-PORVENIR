BEGIN;

SET client_encoding = 'UTF8';

-- Seed aditivo para Cooperativa Minera El Porvenir R.L.
-- No actualiza, elimina ni desactiva registros existentes.
-- Fuentes consultadas:
-- - Cooperativa Minera El Porvenir: registro 3497, Oruro, mineral estano-plomo-zinc.
--   https://www.dateas.com/es/explore/cooperativas-mineras-bolivia/cooperativa-minera-el-porvenir-ltda-714
-- - Informe de monitoreo ambiental 2021-2022: Japo, explotacion subterranea,
--   concentracion, socavon Leonor, cancha mina, ingenio, equipos de planta.
--   https://es.scribd.com/document/657117772/Informe-de-monitoreo-ambiental
-- - Declaracion DGSC 2023: diesel, gasolina, gasolina especial y kerosene
--   para retroexcavadoras, generador, volquetas, pala cargadora, concentracion
--   de minerales, planta, deposito y almacenes del campamento.
--   https://www.studocu.com/bo/document/universidad-tecnica-de-oruro/derecho-civil-contratos/declaracion-jurada-direccion-general-de-sustancias-controladas/72750977
-- - ANH operadores Oruro: Estacion de Servicio Vinto y productos autorizados.
--   https://anh.gob.bo/w2019/contenido.php?D=4&R=1&s=40
-- - Ferrotodo Oruro: proveedor real, NIT, cliente Cooperativa Minera El Porvenir
--   y grupos de productos comercializados.
--   https://es.scribd.com/document/729881949/ferrotodo-esmeralda-terminado
-- - YPFB Refinacion S.A.: productos de lubricantes.
--   https://www.ypfbrefinacion.com.bo/linea-industrial/dx-turbo-sae-15w40-api-ci-4-sl/
--   https://www.ypfbrefinacion.com.bo/linea-industrial/lub-eps/
-- - Epiroc Bolivia: productos, direccion y contacto.
--   https://www.epiroc.com/es-bo/products
-- - CARMAR LTDA., INDITEC S.R.L., ACMIN-BOL y Savicorp: datos legales publicos.
--   https://boliviahub.com/empresa/carmar-ltda-yrs
--   https://boliviahub.com/empresa/inditec-srl-gdf
--   https://boliviahub.com/empresa/acmin-bol-gjf
--   https://boliviahub.com/empresa/minera-savicorp-exportaciones-srl-lge

CREATE TEMP TABLE seed_porvenir_categorias (
  nombre text NOT NULL,
  descripcion text NOT NULL
) ON COMMIT DROP;

INSERT INTO seed_porvenir_categorias (nombre, descripcion)
VALUES
  ('Herramientas y repuestos', 'Herramientas, piezas y repuestos de apoyo a la operacion mina.'),
  ('Seguridad industrial', 'Elementos de proteccion personal y seguridad ocupacional.'),
  ('Lubricantes', 'Aceites, grasas y lubricantes para mantenimiento.'),
  ('Combustible', 'Combustible utilizado en equipos y operacion.'),
  ('Material de perforación', 'Materiales e insumos utilizados en perforacion.'),
  ('Material explosivo controlado', 'Material controlado que requiere registro y almacenamiento especial.');

CREATE TEMP TABLE seed_porvenir_tipos (
  nombre text NOT NULL,
  descripcion text NOT NULL
) ON COMMIT DROP;

INSERT INTO seed_porvenir_tipos (nombre, descripcion)
VALUES
  ('Consumible operativo', 'Insumo que se consume durante la operacion diaria.'),
  ('Herramienta devolutiva', 'Herramienta que debe devolverse despues de su uso.'),
  ('Material fiscalizado', 'Material sujeto a control y fiscalizacion.'),
  ('Repuesto/componente', 'Repuesto o componente de equipos y maquinaria.'),
  ('EPP desechable', 'Equipo de proteccion personal de uso desechable.'),
  ('Material de seguridad', 'Insumo relacionado con seguridad industrial.'),
  ('Combustible', 'Insumo combustible.');

CREATE TEMP TABLE seed_porvenir_unidades (
  nombre text NOT NULL,
  abreviatura text NOT NULL,
  descripcion text NOT NULL
) ON COMMIT DROP;

INSERT INTO seed_porvenir_unidades (nombre, abreviatura, descripcion)
VALUES
  ('Unidad', 'unid', 'Unidad individual.'),
  ('Par', 'par', 'Par de elementos.'),
  ('Litro', 'L', 'Medida de volumen en litros.'),
  ('Kilogramo', 'kg', 'Medida de peso en kilogramos.'),
  ('Caja', 'caja', 'Presentacion por caja.'),
  ('Metro', 'm', 'Medida de longitud en metros.');

DO $$
DECLARE
  item record;
  actor_id integer;
BEGIN
  SELECT u.id_usuario
  INTO actor_id
  FROM public.usuarios u
  WHERE u.nombre_usuario = 'federico'
  ORDER BY u.id_usuario
  LIMIT 1;

  FOR item IN SELECT * FROM seed_porvenir_categorias LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM public.categorias_insumo c
      WHERE UPPER(TRANSLATE(c.nombre_categoria, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun')) =
            UPPER(TRANSLATE(item.nombre, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun'))
    ) THEN
      INSERT INTO public.categorias_insumo (nombre_categoria, descripcion, creado_por)
      VALUES (item.nombre, item.descripcion, actor_id);
    END IF;
  END LOOP;

  FOR item IN SELECT * FROM seed_porvenir_tipos LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM public.tipos_insumo t
      WHERE UPPER(TRANSLATE(t.nombre_tipo, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun')) =
            UPPER(TRANSLATE(item.nombre, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun'))
    ) THEN
      INSERT INTO public.tipos_insumo (nombre_tipo, descripcion, creado_por)
      VALUES (item.nombre, item.descripcion, actor_id);
    END IF;
  END LOOP;

  FOR item IN SELECT * FROM seed_porvenir_unidades LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM public.unidades_medida u
      WHERE UPPER(TRANSLATE(u.nombre_unidad, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun')) =
              UPPER(TRANSLATE(item.nombre, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun'))
         OR UPPER(u.abreviatura) = UPPER(item.abreviatura)
    ) THEN
      INSERT INTO public.unidades_medida (nombre_unidad, abreviatura, descripcion)
      VALUES (item.nombre, item.abreviatura, item.descripcion);
    END IF;
  END LOOP;
END $$;

CREATE TEMP TABLE seed_porvenir_almacenes (
  codigo text NOT NULL,
  nombre text NOT NULL,
  tipo text NOT NULL,
  ubicacion text NOT NULL,
  responsable_usuario text,
  telefono text,
  horario text NOT NULL,
  descripcion text NOT NULL,
  capacidad_maxima numeric,
  capacidad_minima numeric,
  tipo_almacenamiento text,
  observaciones_seguridad text
) ON COMMIT DROP;

INSERT INTO seed_porvenir_almacenes (
  codigo, nombre, tipo, ubicacion, responsable_usuario, telefono, horario,
  descripcion, capacidad_maxima, capacidad_minima, tipo_almacenamiento,
  observaciones_seguridad
)
VALUES
  ('ALM-4', 'Campamento mina Japo', 'SUPERFICIE', 'Localidad de Japo', 'federico', '74477014', 'Lunes a viernes 08:00-16:00', 'Almacen de superficie ubicado en el campamento de la mina otorgado a la cooperativa.', NULL, NULL, 'Deposito de superficie', 'Ingreso restringido a personal autorizado.'),
  ('ALM-5', 'Socavon Leonor', 'SUBTERRANEO', 'Nivel menos treinta', 'miguel', '75759535', 'Bajo control operativo', 'Punto subterraneo asociado al socavon Leonor y niveles San Salvador, menos treinta y menos setenta.', NULL, NULL, 'Resguardo operativo subterraneo', 'Uso sujeto a control de mina y ventilacion.'),
  ('ALM-6', 'Herramientas ingenio', 'HERRAMIENTAS_REPUESTOS', 'Planta tratamiento', 'jose', '74757677', 'Lunes a viernes 08:00-16:00', 'Almacen para herramientas y repuestos de apoyo a chancadora, molinos, mesas, jigs y celdas de flotacion.', NULL, NULL, 'Estantes y resguardo por familia', 'Mantener orden de repuestos y herramientas cortantes.'),
  ('ALM-7', 'Lubricantes planta', 'LUBRICANTES', 'Deposito planta Japo', 'martin', '64958245', 'Lunes a viernes 08:00-16:00', 'Deposito para lubricantes usados en equipos, generador y maquinaria de operacion.', NULL, NULL, 'Tambor, balde y envase cerrado', 'Mantener ventilacion, bandejas de contencion y control de derrames.'),
  ('ALM-8', 'Cancha mina temporal', 'TEMPORAL', 'Cancha mina Japo', 'miguel', '75759535', 'Segun operacion mina', 'Almacen temporal vinculado a la cancha mina donde se acumula carga mineralizada antes del traslado al ingenio.', NULL, NULL, 'Acopio temporal segregado', 'Controlar accesos, senalizacion y permanencia temporal.');

INSERT INTO public.almacenes (
  codigo_almacen, nombre_almacen, tipo_almacen, ubicacion,
  id_responsable_principal, telefono_contacto, horario_atencion,
  descripcion, capacidad_maxima, capacidad_minima_recomendada,
  tipo_almacenamiento, observaciones_seguridad, creado_por
)
SELECT
  a.codigo,
  a.nombre,
  a.tipo,
  a.ubicacion,
  (SELECT u.id_usuario FROM public.usuarios u WHERE u.nombre_usuario = a.responsable_usuario LIMIT 1),
  a.telefono,
  a.horario,
  a.descripcion,
  a.capacidad_maxima,
  a.capacidad_minima,
  a.tipo_almacenamiento,
  a.observaciones_seguridad,
  (SELECT u.id_usuario FROM public.usuarios u WHERE u.nombre_usuario = 'federico' LIMIT 1)
FROM seed_porvenir_almacenes a
WHERE NOT EXISTS (
  SELECT 1
  FROM public.almacenes alm
  WHERE alm.codigo_almacen = a.codigo
     OR (alm.tipo_almacen = a.tipo AND alm.estado <> 'ELIMINADO')
);

CREATE TEMP TABLE seed_porvenir_proveedores (
  codigo text NOT NULL,
  razon_social text NOT NULL,
  nombre_comercial text,
  nit text NOT NULL,
  rubro text NOT NULL,
  tipo_insumos text,
  persona_contacto text,
  cargo_contacto text,
  telefono text,
  celular text,
  correo text,
  direccion text,
  ciudad text,
  observaciones text
) ON COMMIT DROP;

INSERT INTO seed_porvenir_proveedores (
  codigo, razon_social, nombre_comercial, nit, rubro, tipo_insumos,
  persona_contacto, cargo_contacto, telefono, celular, correo, direccion,
  ciudad, observaciones
)
VALUES
  ('PROV-1', 'CARMAR LTDA.', 'CARMAR LTDA.', '1020671027', 'MATERIAL_EXPLOSIVO_CONTROLADO', 'explosivos, accesorios de voladura y reactivos', NULL, NULL, '2434561', '72024347', NULL, 'Ed. Torre Azul piso 4, Nro. 2665', 'La Paz', 'Fuente publica: BoliviaHub; rubro incluye explosivos, accesorios de voladura y reactivos para mineria.'),
  ('PROV-2', 'ESTACION DE SERVICIO VINTO', 'E.S. Vinto', '1020473024', 'COMBUSTIBLE', 'Diesel Oil, Gasolina Especial y Gasolina Especial (+)', NULL, NULL, '5278503', NULL, NULL, 'Carretera Vinto Km. 3.5', 'Oruro', 'Fuente publica: ANH operadores Oruro; NIT tomado del registro local existente.'),
  ('PROV-3', 'AGENCIAS GENERALES S.A.', 'AGSA Bolivia', '1023281020', 'SEGURIDAD_INDUSTRIAL', 'equipos, repuestos, bombas, motores y soporte tecnico', NULL, NULL, '72189998', '72189998', 'web@agsa.com', 'Calle Bolivar E-0520 entre Lanza y San Martin', 'Cochabamba', 'Fuente publica: sitio AGSA y nomina ENDE; proveedor nacional para mineria, industria y soporte tecnico.'),
  ('PROV-4', 'INDUSTRIAS FERROTODO LTDA.', 'Ferrotodo Oruro', '1028373024', 'HERRAMIENTAS_REPUESTOS', 'electrodos, discos, tubos, perfiles y maquinas', 'Fabian Lazo Mercado', 'Gerente regional Oruro', '5275935', NULL, NULL, 'Camino Vinto 1213, lado Tagarete', 'Oruro', 'Fuente publica: documento UTO/Ferrotodo; menciona a Cooperativa Minera El Porvenir como cliente recurrente.'),
  ('PROV-5', 'YPFB REFINACION S.A.', 'Lubricantes YPFB', '1028255024', 'LUBRICANTES', 'GX Extra, DX Turbo, LUB EPS, HAD, FEP y Litiogras', NULL, NULL, NULL, NULL, NULL, NULL, 'La Paz', 'Fuente publica: YPFB Refinacion, lineas de lubricantes automotrices e industriales; NIT verificado en fuentes publicas.'),
  ('PROV-6', 'EPIROC BOLIVIA S.A. EQUIPOS Y SERVICIOS', 'Epiroc Bolivia', '1028237026', 'MATERIAL_PERFORACION', 'equipos y herramientas de perforacion de roca', NULL, NULL, '22112000', '67346636', NULL, 'C. 15 de Calacoto Nro. 8054, edificio Plaza 15, piso 5', 'La Paz', 'Fuente publica: Epiroc Bolivia; NIT verificado en documento publico de contratacion.'),
  ('PROV-7', 'INDITEC S.R.L.', 'INDITEC', '338444021', 'EQUIPOS_MENORES', 'equipos, componentes y herramientas industriales', NULL, NULL, '2731619', '70626212', NULL, 'Nestor Penaranda Nro. 1174', 'La Paz', 'Fuente publica: BoliviaHub; rubro de equipos, componentes, partes y herramientas industriales.'),
  ('PROV-8', 'ACMIN - BOL', 'ACMIN - BOL', '5505594013', 'SERVICIOS_COMPLEMENTARIOS', 'perforacion, voladura, transporte y alquiler', NULL, NULL, NULL, '67601240', NULL, 'Nro. 27', 'Sucre', 'Fuente publica: BoliviaHub; servicios mineros, movimiento de tierra, perforacion, voladura, transporte y alquiler de maquinaria.'),
  ('PROV-9', 'MINERA SAVICORP EXPORTACIONES S.R.L.', 'Savicorp', '557875021', 'OTROS', 'insumos quimicos, materiales y servicios toll', NULL, NULL, NULL, '67941524', NULL, 'Circunvalacion Nro. S/N', 'Potosi', 'Fuente publica: BoliviaHub; importacion y comercializacion de equipos, insumos quimicos y materiales para mineria.');

INSERT INTO public.proveedores (
  codigo_proveedor, razon_social, nombre_comercial, nit, rubro,
  tipo_insumos_provee, persona_contacto, cargo_contacto, telefono,
  celular_whatsapp, correo, direccion, ciudad, condiciones_pago, forma_pago,
  tiempo_estimado_entrega, calificacion, documentacion_vigente, estado,
  observaciones, creado_por
)
SELECT
  p.codigo,
  p.razon_social,
  p.nombre_comercial,
  p.nit,
  p.rubro,
  p.tipo_insumos,
  p.persona_contacto,
  p.cargo_contacto,
  p.telefono,
  p.celular,
  p.correo,
  p.direccion,
  p.ciudad,
  NULL,
  NULL,
  NULL,
  NULL,
  TRUE,
  'ACTIVO',
  p.observaciones,
  (SELECT u.id_usuario FROM public.usuarios u WHERE u.nombre_usuario = 'federico' LIMIT 1)
FROM seed_porvenir_proveedores p
WHERE NOT EXISTS (
  SELECT 1
  FROM public.proveedores pr
  WHERE pr.codigo_proveedor = p.codigo
     OR pr.nit = p.nit
     OR (pr.rubro = p.rubro AND pr.estado <> 'ELIMINADO')
);

CREATE TEMP TABLE seed_porvenir_insumos (
  codigo text NOT NULL,
  qr text NOT NULL,
  categoria text NOT NULL,
  tipo text NOT NULL,
  unidad text NOT NULL,
  nombre text NOT NULL,
  descripcion text NOT NULL,
  marca text,
  modelo text,
  presentacion text,
  ubicacion text,
  control_especial boolean NOT NULL DEFAULT FALSE,
  inflamable boolean NOT NULL DEFAULT FALSE,
  proveedor_codigo text,
  observaciones text NOT NULL
) ON COMMIT DROP;

INSERT INTO seed_porvenir_insumos (
  codigo, qr, categoria, tipo, unidad, nombre, descripcion, marca, modelo,
  presentacion, ubicacion, control_especial, inflamable, proveedor_codigo,
  observaciones
)
VALUES
  ('PV-HR-01', 'QR-PV-HR-01', 'Herramientas y repuestos', 'Consumible operativo', 'kg', 'Electrodos revestidos', 'Grupo de producto comercializado por Ferrotodo para soldadura de acero.', 'Ferrotodo / ESAB', NULL, 'Kilogramo', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-02', 'QR-PV-HR-02', 'Herramientas y repuestos', 'Consumible operativo', 'kg', 'Alambre de acero', 'Grupo de producto comercializado por Ferrotodo para amarre y trabajos metalmecanicos.', 'Ferrotodo', NULL, 'Kilogramo', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-03', 'QR-PV-HR-03', 'Herramientas y repuestos', 'Consumible operativo', 'unid', 'Lija para hierro', 'Lijas para trabajos sobre hierro comercializadas por Ferrotodo.', 'Ferrotodo', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-04', 'QR-PV-HR-04', 'Herramientas y repuestos', 'Consumible operativo', 'unid', 'Disco corte Norton', 'Disco de corte de la marca Norton Saint-Gobain comercializado por Ferrotodo.', 'Norton Saint-Gobain', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-05', 'QR-PV-HR-05', 'Herramientas y repuestos', 'Consumible operativo', 'unid', 'Disco desbaste Norton', 'Disco de desbaste de la marca Norton Saint-Gobain comercializado por Ferrotodo.', 'Norton Saint-Gobain', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-06', 'QR-PV-HR-06', 'Herramientas y repuestos', 'Consumible operativo', 'unid', 'Piedra esmeril Norton', 'Piedra esmeril del grupo de discos y abrasivos comercializado por Ferrotodo.', 'Norton Saint-Gobain', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-07', 'QR-PV-HR-07', 'Herramientas y repuestos', 'Repuesto/componente', 'm', 'Tubo de acero', 'Tubo de acero fabricado y comercializado por Industrias Ferrotodo Ltda.', 'Ferrotodo', NULL, 'Metro', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-08', 'QR-PV-HR-08', 'Herramientas y repuestos', 'Repuesto/componente', 'm', 'Perfil costanera', 'Perfil o costanera de acero comercializado por Industrias Ferrotodo Ltda.', 'Ferrotodo', NULL, 'Metro', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-09', 'QR-PV-HR-09', 'Herramientas y repuestos', 'Repuesto/componente', 'unid', 'Plancha de acero', 'Plancha de acero comercializada por Industrias Ferrotodo Ltda.', 'Ferrotodo', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-HR-10', 'QR-PV-HR-10', 'Herramientas y repuestos', 'Repuesto/componente', 'm', 'Acero redondo Acindar', 'Acero redondo del grupo ACINDAR ArcelorMittal citado entre marcas de Ferrotodo.', 'ACINDAR ArcelorMittal', NULL, 'Metro', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-EQ-01', 'QR-PV-EQ-01', 'Herramientas y repuestos', 'Herramienta devolutiva', 'unid', 'Maquina soldar ESAB', 'Maquina de soldar ESAB comercializada por Ferrotodo.', 'ESAB', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-EQ-02', 'QR-PV-EQ-02', 'Herramientas y repuestos', 'Herramienta devolutiva', 'unid', 'Taladro Vonder', 'Taladro Vonder comercializado por Ferrotodo.', 'Vonder', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-EQ-03', 'QR-PV-EQ-03', 'Herramientas y repuestos', 'Herramienta devolutiva', 'unid', 'Amoladora Vonder', 'Amoladora Vonder comercializada por Ferrotodo.', 'Vonder', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-EQ-04', 'QR-PV-EQ-04', 'Herramientas y repuestos', 'Herramienta devolutiva', 'unid', 'Pulverizadora Vonder', 'Pulverizadora Vonder comercializada por Ferrotodo.', 'Vonder', NULL, 'Unidad', 'ALM-6 Herramientas ingenio', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-SI-02', 'QR-PV-SI-02', 'Seguridad industrial', 'Material de seguridad', 'unid', 'Casco soldar ESAB', 'Casco para soldar ESAB citado entre productos comercializados por Ferrotodo.', 'ESAB', NULL, 'Unidad', 'ALM-2 Seguridad industrial', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-SI-03', 'QR-PV-SI-03', 'Seguridad industrial', 'Material de seguridad', 'unid', 'Gafas industriales', 'Gafas industriales citadas entre productos comercializados por Ferrotodo.', 'Ferrotodo', NULL, 'Unidad', 'ALM-2 Seguridad industrial', FALSE, FALSE, 'PROV-4', 'Producto real listado por Ferrotodo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-LB-01', 'QR-PV-LB-01', 'Lubricantes', 'Consumible operativo', 'L', 'GX Extra SAE 15W40', 'Lubricante multigrado YPFB GX Extra SAE 15W-40 API SL/CF.', 'YPFB', 'GX Extra SAE 15W-40 API SL/CF', 'Litro', 'ALM-7 Lubricantes planta', FALSE, FALSE, 'PROV-5', 'Producto real publicado por YPFB Refinacion. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-LB-02', 'QR-PV-LB-02', 'Lubricantes', 'Consumible operativo', 'L', 'DX Turbo SAE 15W40', 'Lubricante YPFB DX Turbo SAE 15W40 API CI-4/SL para motores diesel.', 'YPFB', 'DX Turbo SAE 15W40 API CI-4/SL', 'Litro', 'ALM-7 Lubricantes planta', FALSE, FALSE, 'PROV-5', 'Producto real publicado por YPFB Refinacion. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-LB-03', 'QR-PV-LB-03', 'Lubricantes', 'Consumible operativo', 'L', 'LUB EPS', 'Lubricante industrial YPFB LUB EPS de extrema presion.', 'YPFB', 'LUB EPS', 'Litro', 'ALM-7 Lubricantes planta', FALSE, FALSE, 'PROV-5', 'Producto real publicado por YPFB Refinacion. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-LB-04', 'QR-PV-LB-04', 'Lubricantes', 'Consumible operativo', 'L', 'LUB HAD TP', 'Lubricante hidraulico anti-desgaste de trabajo pesado de YPFB.', 'YPFB', 'LUB HAD TP', 'Litro', 'ALM-7 Lubricantes planta', FALSE, FALSE, 'PROV-5', 'Producto real publicado por YPFB Refinacion. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-LB-05', 'QR-PV-LB-05', 'Lubricantes', 'Consumible operativo', 'L', 'LUB FEP', 'Fluido para equipo pesado de la linea industrial YPFB.', 'YPFB', 'LUB FEP', 'Litro', 'ALM-7 Lubricantes planta', FALSE, FALSE, 'PROV-5', 'Producto real publicado por YPFB Refinacion. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-LB-06', 'QR-PV-LB-06', 'Lubricantes', 'Consumible operativo', 'L', 'LUB MPN', 'Aceite YPFB para perforadoras neumaticas.', 'YPFB', 'LUB MPN', 'Litro', 'ALM-7 Lubricantes planta', FALSE, FALSE, 'PROV-5', 'Producto real publicado por YPFB Refinacion. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-LB-07', 'QR-PV-LB-07', 'Lubricantes', 'Consumible operativo', 'kg', 'Litiogras NLGI 2', 'Grasa YPFB Litiogras NLGI numero 2 y 3.', 'YPFB', 'LITIOGRAS NLGI Nro 2-3', 'Kilogramo', 'ALM-7 Lubricantes planta', FALSE, FALSE, 'PROV-5', 'Producto real publicado por YPFB Refinacion. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-CU-02', 'QR-PV-CU-02', 'Combustible', 'Combustible', 'L', 'Gasolina', 'Sustancia controlada declarada para uso operativo de la cooperativa.', 'ANH / mercado regulado', NULL, 'Litro', 'ALM-3 Combustible', TRUE, TRUE, 'PROV-2', 'Producto declarado por la cooperativa ante DGSC. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-CU-03', 'QR-PV-CU-03', 'Combustible', 'Combustible', 'L', 'Gasolina Especial', 'Producto autorizado en Estacion de Servicio Vinto segun listado ANH Oruro.', 'ANH / mercado regulado', NULL, 'Litro', 'ALM-3 Combustible', TRUE, TRUE, 'PROV-2', 'Producto real publicado por ANH y declarado como consumo operativo. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-CU-04', 'QR-PV-CU-04', 'Combustible', 'Combustible', 'L', 'Kerosene', 'Sustancia controlada declarada para uso operativo de la cooperativa.', 'ANH / mercado regulado', NULL, 'Litro', 'ALM-3 Combustible', TRUE, TRUE, 'PROV-2', 'Producto declarado por la cooperativa ante DGSC. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-MP-01', 'QR-PV-MP-01', 'Material de perforación', 'Herramienta devolutiva', 'unid', 'Boomer M1 L Epiroc', 'Equipo de perforacion frontal hidraulico Epiroc para mineria subterranea.', 'Epiroc', 'Boomer M1 L', 'Unidad', 'ALM-5 Socavon Leonor', FALSE, FALSE, 'PROV-6', 'Producto real publicado por Epiroc Bolivia. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-MP-02', 'QR-PV-MP-02', 'Material de perforación', 'Herramienta devolutiva', 'unid', 'FlexiROC T45 Epiroc', 'Equipo de perforacion con martillo en cabeza Epiroc para mineria y canteras.', 'Epiroc', 'FlexiROC T45', 'Unidad', 'ALM-8 Cancha mina temporal', FALSE, FALSE, 'PROV-6', 'Producto real publicado por Epiroc Bolivia. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-MP-03', 'QR-PV-MP-03', 'Material de perforación', 'Herramienta devolutiva', 'unid', 'FlexiROC D60 Epiroc', 'Equipo de perforacion DTH Epiroc para mineria y canteras.', 'Epiroc', 'FlexiROC D60', 'Unidad', 'ALM-8 Cancha mina temporal', FALSE, FALSE, 'PROV-6', 'Producto real publicado por Epiroc Bolivia. Precio y stock minimo no publicados; se dejan en 0.'),
  ('PV-EX-01', 'QR-PV-EX-01', 'Material explosivo controlado', 'Material fiscalizado', 'caja', 'Emulnor 1000', 'Emulsion encartuchada Emulnor 1000 de Famesa, material fiscalizado.', 'Famesa', 'Emulnor 1000', 'Caja', 'ALM-1 Polvorin', TRUE, TRUE, 'PROV-1', 'Producto real de Famesa/CARMAR. Precio y stock minimo no publicados; se dejan en 0.');

INSERT INTO public.insumos (
  id_categoria, id_tipo_insumo, id_unidad_medida, codigo_interno,
  codigo_barra_qr, nombre_insumo, descripcion, marca, modelo, presentacion,
  precio_referencial, stock_minimo, ubicacion_sugerida,
  requiere_control_especial, es_peligroso_inflamable, estado, observaciones,
  creado_por
)
SELECT
  (
    SELECT c.id_categoria
    FROM public.categorias_insumo c
    WHERE UPPER(TRANSLATE(c.nombre_categoria, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun')) =
          UPPER(TRANSLATE(i.categoria, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun'))
    LIMIT 1
  ),
  (
    SELECT t.id_tipo_insumo
    FROM public.tipos_insumo t
    WHERE UPPER(TRANSLATE(t.nombre_tipo, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun')) =
          UPPER(TRANSLATE(i.tipo, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun'))
    LIMIT 1
  ),
  (
    SELECT u.id_unidad_medida
    FROM public.unidades_medida u
    WHERE UPPER(u.abreviatura) = UPPER(i.unidad)
    LIMIT 1
  ),
  i.codigo,
  i.qr,
  i.nombre,
  i.descripcion,
  i.marca,
  i.modelo,
  i.presentacion,
  0,
  0,
  i.ubicacion,
  i.control_especial,
  i.inflamable,
  'ACTIVO',
  i.observaciones,
  (SELECT u.id_usuario FROM public.usuarios u WHERE u.nombre_usuario = 'federico' LIMIT 1)
FROM seed_porvenir_insumos i
WHERE NOT EXISTS (
  SELECT 1
  FROM public.insumos ins
  WHERE ins.codigo_interno = i.codigo
     OR ins.codigo_barra_qr = i.qr
);

INSERT INTO public.proveedor_insumo (
  id_proveedor, id_insumo, precio_referencial, tiempo_entrega_dias, estado
)
SELECT
  p.id_proveedor,
  ins.id_insumo,
  0,
  NULL,
  'ACTIVO'
FROM seed_porvenir_insumos i
INNER JOIN public.insumos ins ON ins.codigo_interno = i.codigo
INNER JOIN seed_porvenir_proveedores sp ON sp.codigo = i.proveedor_codigo
INNER JOIN public.proveedores p
  ON p.codigo_proveedor = sp.codigo
 AND p.nit = sp.nit
WHERE i.proveedor_codigo IS NOT NULL
  AND NOT EXISTS (
    SELECT 1
    FROM public.proveedor_insumo pi
    WHERE pi.id_proveedor = p.id_proveedor
      AND pi.id_insumo = ins.id_insumo
  );

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.usuarios WHERE estado = 'ACTIVO') THEN
    RAISE EXCEPTION 'No hay usuarios activos para crear pedidos de carga inicial.';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.areas WHERE estado = 'ACTIVO') THEN
    RAISE EXCEPTION 'No hay areas activas para crear pedidos de carga inicial.';
  END IF;
END $$;

CREATE TEMP TABLE seed_porvenir_pedidos (
  numero text NOT NULL,
  usuario text NOT NULL,
  area text NOT NULL,
  fecha_pedido timestamptz NOT NULL,
  fecha_requerida timestamptz NOT NULL,
  tipo text NOT NULL,
  prioridad text NOT NULL,
  justificacion text NOT NULL,
  proveedor_codigo text,
  centro_costo text,
  lugar_uso text,
  turno_guardia text,
  observaciones text NOT NULL,
  insumo_codigo text NOT NULL,
  cantidad numeric NOT NULL,
  detalle_observacion text NOT NULL
) ON COMMIT DROP;

-- No existen fuentes publicas con 25 pedidos historicos firmados de la cooperativa.
-- Por eso estos pedidos quedan PENDIENTES y marcados como carga inicial basada en
-- actividades, ubicaciones, equipos e insumos reales documentados.
INSERT INTO seed_porvenir_pedidos (
  numero, usuario, area, fecha_pedido, fecha_requerida, tipo, prioridad,
  justificacion, proveedor_codigo, centro_costo, lugar_uso, turno_guardia,
  observaciones, insumo_codigo, cantidad, detalle_observacion
)
VALUES
  ('PED-PV-001/2026', 'miguel', 'Operaciones / Mina', '2026-09-03 08:00:00-04', '2026-09-04 08:00:00-04', 'OPERACION', 'ALTA', 'Dotacion de gafas industriales para labores de interior mina y manipuleo de carga mineralizada.', 'PROV-4', 'CC-MINA-JAPO', 'Socavon Leonor', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-SI-03', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-002/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 08:15:00-04', '2026-09-05 08:00:00-04', 'MANTENIMIENTO', 'MEDIA', 'Casco para soldar en trabajos de mantenimiento de equipos de planta.', 'PROV-4', 'CC-MANT-JAPO', 'Herramientas ingenio', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-SI-02', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-003/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 08:30:00-04', '2026-09-05 08:00:00-04', 'MANTENIMIENTO', 'MEDIA', 'Electrodos revestidos para reparacion de estructuras metalicas en el ingenio.', 'PROV-4', 'CC-MANT-JAPO', 'Planta tratamiento', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-01', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-004/2026', 'miguel', 'Operaciones / Mina', '2026-09-03 08:45:00-04', '2026-09-06 08:00:00-04', 'NORMAL', 'BAJA', 'Alambre de acero para trabajos auxiliares de amarre en superficie.', 'PROV-4', 'CC-MINA-JAPO', 'Campamento mina Japo', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-02', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-005/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 09:00:00-04', '2026-09-04 08:00:00-04', 'MANTENIMIENTO', 'ALTA', 'Discos de corte para reparaciones de tubos y perfiles en planta.', 'PROV-4', 'CC-MANT-JAPO', 'Herramientas ingenio', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-04', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-006/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 09:15:00-04', '2026-09-06 08:00:00-04', 'MANTENIMIENTO', 'MEDIA', 'Discos de desbaste para acabado de reparaciones metalmecanicas.', 'PROV-4', 'CC-MANT-JAPO', 'Herramientas ingenio', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-05', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-007/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 09:30:00-04', '2026-09-07 08:00:00-04', 'REPOSICION', 'BAJA', 'Piedra esmeril para afilado de herramientas de taller.', 'PROV-4', 'CC-MANT-JAPO', 'Herramientas ingenio', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-06', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-008/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 09:45:00-04', '2026-09-07 08:00:00-04', 'REPOSICION', 'MEDIA', 'Tubo de acero para reposicion de tramos en mantenimiento de planta.', 'PROV-4', 'CC-MANT-JAPO', 'Planta tratamiento', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-07', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-009/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 10:00:00-04', '2026-09-08 08:00:00-04', 'REPOSICION', 'MEDIA', 'Perfil costanera para mantenimiento de estructuras del campamento.', 'PROV-4', 'CC-MANT-JAPO', 'Campamento mina Japo', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-08', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-010/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 10:15:00-04', '2026-09-05 08:00:00-04', 'MANTENIMIENTO', 'ALTA', 'Plancha de acero para reparacion de buzon y protecciones de planta.', 'PROV-4', 'CC-MANT-JAPO', 'Planta tratamiento', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-09', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-011/2026', 'martin', 'Logística / Almacenes', '2026-09-03 10:30:00-04', '2026-09-04 08:00:00-04', 'MANTENIMIENTO', 'URGENTE', 'DX Turbo 15W40 para mantenimiento de equipos diesel como volquetas y pala cargadora.', 'PROV-5', 'CC-LUB-JAPO', 'Lubricantes planta', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-LB-02', 1, 'Producto real publicado por YPFB Refinacion.'),
  ('PED-PV-012/2026', 'martin', 'Logística / Almacenes', '2026-09-03 10:45:00-04', '2026-09-06 08:00:00-04', 'MANTENIMIENTO', 'MEDIA', 'LUB EPS para transmisiones y reductores sometidos a carga en planta.', 'PROV-5', 'CC-LUB-JAPO', 'Lubricantes planta', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-LB-03', 1, 'Producto real publicado por YPFB Refinacion.'),
  ('PED-PV-013/2026', 'martin', 'Logística / Almacenes', '2026-09-03 11:00:00-04', '2026-09-05 08:00:00-04', 'MANTENIMIENTO', 'ALTA', 'LUB HAD TP para sistemas hidraulicos de retroexcavadora y pala cargadora.', 'PROV-5', 'CC-LUB-JAPO', 'Lubricantes planta', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-LB-04', 1, 'Producto real publicado por YPFB Refinacion.'),
  ('PED-PV-014/2026', 'miguel', 'Operaciones / Mina', '2026-09-03 11:15:00-04', '2026-09-05 08:00:00-04', 'OPERACION', 'ALTA', 'LUB MPN para perforadoras neumaticas asociadas a perforacion con aire comprimido.', 'PROV-5', 'CC-MINA-JAPO', 'Socavon Leonor', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-LB-06', 1, 'Producto real publicado por YPFB Refinacion.'),
  ('PED-PV-015/2026', 'martin', 'Logística / Almacenes', '2026-09-03 11:30:00-04', '2026-09-05 08:00:00-04', 'OPERACION', 'MEDIA', 'Gasolina para equipos declarados con consumo de sustancia controlada.', 'PROV-2', 'CC-COMB-JAPO', 'Almacen combustible', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-CU-02', 1, 'Producto declarado ante DGSC.'),
  ('PED-PV-016/2026', 'martin', 'Logística / Almacenes', '2026-09-03 11:45:00-04', '2026-09-05 08:00:00-04', 'OPERACION', 'MEDIA', 'Gasolina Especial para equipos de apoyo y transporte interno.', 'PROV-2', 'CC-COMB-JAPO', 'Almacen combustible', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-CU-03', 1, 'Producto real autorizado por ANH.'),
  ('PED-PV-017/2026', 'martin', 'Logística / Almacenes', '2026-09-03 12:00:00-04', '2026-09-04 08:00:00-04', 'OPERACION', 'ALTA', 'Kerosene declarado para uso operativo sujeto a control.', 'PROV-2', 'CC-COMB-JAPO', 'Almacen combustible', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-CU-04', 1, 'Producto declarado ante DGSC.'),
  ('PED-PV-018/2026', 'miguel', 'Operaciones / Mina', '2026-09-03 12:15:00-04', '2026-09-09 08:00:00-04', 'NORMAL', 'BAJA', 'Boomer M1 L para evaluacion de alternativa de perforacion frontal en galerias.', 'PROV-6', 'CC-MINA-JAPO', 'Socavon Leonor', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-MP-01', 1, 'Producto real publicado por Epiroc Bolivia.'),
  ('PED-PV-019/2026', 'miguel', 'Operaciones / Mina', '2026-09-03 12:30:00-04', '2026-09-09 08:00:00-04', 'NORMAL', 'BAJA', 'FlexiROC T45 para evaluacion de alternativa de perforacion en superficie.', 'PROV-6', 'CC-MINA-JAPO', 'Cancha mina Japo', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-MP-02', 1, 'Producto real publicado por Epiroc Bolivia.'),
  ('PED-PV-020/2026', 'miguel', 'Operaciones / Mina', '2026-09-03 12:45:00-04', '2026-09-09 08:00:00-04', 'NORMAL', 'BAJA', 'FlexiROC D60 para evaluacion de perforacion DTH de superficie.', 'PROV-6', 'CC-MINA-JAPO', 'Cancha mina Japo', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-MP-03', 1, 'Producto real publicado por Epiroc Bolivia.'),
  ('PED-PV-021/2026', 'miguel', 'Operaciones / Mina', '2026-09-03 13:00:00-04', '2026-09-04 08:00:00-04', 'EMERGENCIA', 'URGENTE', 'Emulnor 1000 para reposicion de material fiscalizado de voladura.', 'PROV-1', 'CC-POL-JAPO', 'Polvorin', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-EX-01', 1, 'Producto real de Famesa/CARMAR; requiere control legal.'),
  ('PED-PV-022/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 13:15:00-04', '2026-09-08 08:00:00-04', 'MANTENIMIENTO', 'BAJA', 'Lija para hierro para trabajos de acabado y limpieza de piezas metalicas.', 'PROV-4', 'CC-MANT-JAPO', 'Herramientas ingenio', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-03', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-023/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 13:30:00-04', '2026-09-07 08:00:00-04', 'MANTENIMIENTO', 'MEDIA', 'Taladro Vonder para trabajos de reparacion en maestranza.', 'PROV-4', 'CC-MANT-JAPO', 'Herramientas ingenio', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-EQ-02', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-024/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 13:45:00-04', '2026-09-07 08:00:00-04', 'MANTENIMIENTO', 'MEDIA', 'Amoladora Vonder para corte y desbaste en mantenimiento.', 'PROV-4', 'CC-MANT-JAPO', 'Herramientas ingenio', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-EQ-03', 1, 'Producto real comercializado por Ferrotodo.'),
  ('PED-PV-025/2026', 'jose', 'Mantenimiento / Maestranza', '2026-09-03 14:00:00-04', '2026-09-08 08:00:00-04', 'MANTENIMIENTO', 'MEDIA', 'Acero redondo Acindar para reparaciones metalicas auxiliares.', 'PROV-4', 'CC-MANT-JAPO', 'Herramientas ingenio', 'Guardia dia', 'Carga inicial basada en operaciones documentadas; no es pedido historico firmado.', 'PV-HR-10', 1, 'Producto real comercializado por Ferrotodo.');

INSERT INTO public.pedidos (
  numero_pedido, id_usuario_solicitante, id_area_solicitante, fecha_pedido,
  fecha_requerida, tipo_pedido, prioridad, justificacion, estado_pedido,
  estado_aprobacion, estado_atencion, id_proveedor_sugerido, centro_costo,
  lugar_uso, turno_guardia, observaciones, creado_por
)
SELECT
  p.numero,
  COALESCE(
    (SELECT u.id_usuario FROM public.usuarios u WHERE u.nombre_usuario = p.usuario LIMIT 1),
    (SELECT u.id_usuario FROM public.usuarios u WHERE u.estado = 'ACTIVO' ORDER BY u.id_usuario LIMIT 1)
  ),
  COALESCE(
    (
      SELECT a.id_area
      FROM public.areas a
      WHERE a.estado = 'ACTIVO'
        AND UPPER(TRANSLATE(a.nombre_area, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun')) =
            UPPER(TRANSLATE(p.area, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun'))
      LIMIT 1
    ),
    (SELECT a.id_area FROM public.areas a WHERE a.estado = 'ACTIVO' ORDER BY a.id_area LIMIT 1)
  ),
  p.fecha_pedido,
  p.fecha_requerida,
  p.tipo,
  p.prioridad,
  p.justificacion,
  'PENDIENTE',
  'PENDIENTE',
  'SIN_ATENDER',
  (
    SELECT pr.id_proveedor
    FROM seed_porvenir_proveedores sp
    INNER JOIN public.proveedores pr
      ON pr.codigo_proveedor = sp.codigo
     AND pr.nit = sp.nit
    WHERE sp.codigo = p.proveedor_codigo
    LIMIT 1
  ),
  p.centro_costo,
  p.lugar_uso,
  p.turno_guardia,
  p.observaciones,
  COALESCE(
    (SELECT u.id_usuario FROM public.usuarios u WHERE u.nombre_usuario = p.usuario LIMIT 1),
    (SELECT u.id_usuario FROM public.usuarios u WHERE u.estado = 'ACTIVO' ORDER BY u.id_usuario LIMIT 1)
  )
FROM seed_porvenir_pedidos p
WHERE NOT EXISTS (
  SELECT 1
  FROM public.pedidos pe
  WHERE pe.numero_pedido = p.numero
);

INSERT INTO public.pedido_detalles (
  id_pedido, id_insumo, cantidad_solicitada, cantidad_aprobada,
  cantidad_despachada, observacion
)
SELECT
  pe.id_pedido,
  ins.id_insumo,
  p.cantidad,
  0,
  0,
  p.detalle_observacion
FROM seed_porvenir_pedidos p
INNER JOIN public.pedidos pe ON pe.numero_pedido = p.numero
INNER JOIN public.insumos ins ON ins.codigo_interno = p.insumo_codigo
WHERE NOT EXISTS (
  SELECT 1
  FROM public.pedido_detalles pd
  WHERE pd.id_pedido = pe.id_pedido
    AND pd.id_insumo = ins.id_insumo
    AND pd.observacion = p.detalle_observacion
);

COMMIT;
