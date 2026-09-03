-- Usuario administrador personal para usar junto con la base completa.
-- Credenciales: federico / fede2002

BEGIN;

WITH admin_area AS (
  SELECT id_area
  FROM areas
  ORDER BY
    CASE WHEN lower(nombre_area) LIKE 'admin%' THEN 0 ELSE 1 END,
    id_area
  LIMIT 1
),
admin_role AS (
  SELECT id_rol
  FROM roles
  WHERE nombre_rol = 'Administrador del sistema'
  LIMIT 1
)
INSERT INTO usuarios (
  id_area,
  id_rol,
  nombre_completo,
  nombre_usuario,
  correo,
  cedula_identidad,
  complemento_ci,
  expedido_ci,
  password_hash,
  telefono,
  cargo,
  estado,
  intentos_fallidos,
  cambio_obligatorio
)
SELECT
  admin_area.id_area,
  admin_role.id_rol,
  'federico choquecallata villca',
  'federico',
  'feyckon@gmail.com',
  '12901305',
  NULL,
  'OR',
  '$2b$10$GgdiHI4w3VT.ZUWQZCyWx.1vCXIlRKPeL76SvnYgrSDKA12MncroC',
  '74477014',
  'presidente de Vigilancia',
  'ACTIVO',
  0,
  FALSE
FROM admin_area
CROSS JOIN admin_role
ON CONFLICT (nombre_usuario)
DO UPDATE SET
  id_area = EXCLUDED.id_area,
  id_rol = EXCLUDED.id_rol,
  nombre_completo = EXCLUDED.nombre_completo,
  correo = EXCLUDED.correo,
  cedula_identidad = EXCLUDED.cedula_identidad,
  complemento_ci = EXCLUDED.complemento_ci,
  expedido_ci = EXCLUDED.expedido_ci,
  password_hash = EXCLUDED.password_hash,
  telefono = EXCLUDED.telefono,
  cargo = EXCLUDED.cargo,
  estado = 'ACTIVO',
  intentos_fallidos = 0,
  cambio_obligatorio = FALSE,
  fecha_actualizacion = NOW();

COMMIT;
