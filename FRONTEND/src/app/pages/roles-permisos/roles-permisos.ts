import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { UsuariosService } from '../../core/services/usuarios.service';
import { ROLE_PERMISSIONS } from '../../core/security/role-permissions';
import { normalizarRol } from '../../core/utils/roles.util';

interface RolSistema {
  codigo: string;
  nombre: string;
  descripcion: string;
  permisos: string[];
  color: string;
  icono: string;
}

@Component({
  selector: 'app-roles-permisos',
  standalone: true,
  imports: [RouterLink],
  templateUrl: './roles-permisos.html',
  styleUrl: './roles-permisos.css',
})
export class RolesPermisos {
  private readonly usuariosService = inject(UsuariosService);

  cargando = signal(false);
  error = signal('');
  busqueda = signal('');
  rolSeleccionado = signal<RolSistema | null>(null);
  usuarios = signal<any[]>([]);

  roles = signal<RolSistema[]>([
    this.crearRol(
      'ADMINISTRADOR',
      'Administrador del sistema',
      'Control total del sistema, usuarios, seguridad, reportes y auditoria.',
      'AD',
      'bg-slate-950 text-white border-slate-800',
    ),
    this.crearRol(
      'ENCARGADO_ALMACEN',
      'Encargado de almacén',
      'Responsable del control fisico de insumos, stock, movimientos y despachos.',
      'AL',
      'bg-blue-600 text-white border-blue-700',
    ),
    this.crearRol(
      'SUPERVISOR_MINA',
      'Supervisor de mina',
      'Solicita insumos para operacion minera y realiza seguimiento a pedidos.',
      'SM',
      'bg-orange-600 text-white border-orange-700',
    ),
    this.crearRol(
      'JEFE_AREA',
      'Jefe de área',
      'Aprueba, rechaza u observa pedidos de su area.',
      'JA',
      'bg-green-600 text-white border-green-700',
    ),
    this.crearRol(
      'ENCARGADO_COMPRAS',
      'Encargado de compras',
      'Gestiona proveedores, ordenes de compra, recepciones y comprobantes.',
      'CO',
      'bg-violet-600 text-white border-violet-700',
    ),
    this.crearRol(
      'AUDITOR',
      'Auditor',
      'Consulta trazabilidad, reportes, movimientos y registros de auditoria.',
      'AU',
      'bg-red-600 text-white border-red-700',
    ),
    this.crearRol(
      'USUARIO_SOLICITANTE',
      'Usuario solicitante',
      'Crea pedidos de insumos y realiza seguimiento a sus solicitudes.',
      'US',
      'bg-cyan-600 text-white border-cyan-700',
    ),
  ]);

  rolesFiltrados = computed(() => {
    const texto = this.busqueda().trim().toLowerCase();

    if (!texto) {
      return this.roles();
    }

    return this.roles().filter((rol) => {
      return (
        rol.nombre.toLowerCase().includes(texto) ||
        rol.codigo.toLowerCase().includes(texto) ||
        rol.descripcion.toLowerCase().includes(texto) ||
        rol.permisos.join(' ').toLowerCase().includes(texto)
      );
    });
  });

  totalRoles = computed(() => this.roles().length);

  totalPermisos = computed(() => {
    const permisos = new Set<string>();

    this.roles().forEach((rol) => {
      rol.permisos.forEach((permiso) => permisos.add(permiso));
    });

    return permisos.size;
  });

  totalUsuarios = computed(() => this.usuarios().length);

  totalUsuariosActivos = computed(() => {
    return this.usuarios().filter((usuario) => {
      const estado = String(
        usuario.estado || usuario.estadoUsuario || usuario.estado_usuario || '',
      ).toUpperCase();
      return estado.includes('ACTIVO') || estado === 'TRUE' || estado === '1' || estado === '';
    }).length;
  });

  ngOnInit() {
    this.cargarUsuarios();
  }

  cargarUsuarios() {
    this.cargando.set(true);
    this.error.set('');

    this.usuariosService.listar().subscribe({
      next: (data: any) => {
        this.usuarios.set(this.normalizarArray(data));
        this.cargando.set(false);
      },
      error: () => {
        this.usuarios.set([]);
        this.error.set('No se pudo cargar usuarios. Los roles y permisos se muestran igualmente.');
        this.cargando.set(false);
      },
    });
  }

  normalizarArray(data: any): any[] {
    if (Array.isArray(data)) return data;
    if (Array.isArray(data?.data)) return data.data;
    if (Array.isArray(data?.items)) return data.items;
    if (Array.isArray(data?.registros)) return data.registros;
    return [];
  }

  cambiarBusqueda(event: Event) {
    const input = event.target as HTMLInputElement;
    this.busqueda.set(input.value);
  }

  seleccionarRol(rol: RolSistema) {
    this.rolSeleccionado.set(rol);
  }

  cerrarDetalle() {
    this.rolSeleccionado.set(null);
  }

  usuariosPorRol(codigoRol: string): number {
    return this.usuarios().filter((usuario) => {
      const rol = this.obtenerRolUsuario(usuario);
      return rol === codigoRol;
    }).length;
  }

  obtenerRolUsuario(usuario: any): string {
    const rol =
      usuario.rol?.nombreRol ||
      usuario.rol?.nombre_rol ||
      usuario.rol?.codigo ||
      usuario.rol?.codigoRol ||
      usuario.rol?.codigo_rol ||
      usuario.nombreRol ||
      usuario.nombre_rol ||
      usuario.codigoRol ||
      usuario.codigo_rol ||
      usuario.rol ||
      '';

    return normalizarRol(String(rol));
  }

  porcentajePermisos(rol: RolSistema): number {
    if (this.totalPermisos() === 0) {
      return 0;
    }

    return Math.round((rol.permisos.length / this.totalPermisos()) * 100);
  }

  trackPermiso(index: number, permiso: string) {
    return `${index}-${permiso}`;
  }

  private crearRol(
    codigo: string,
    nombre: string,
    descripcion: string,
    icono: string,
    color: string,
  ): RolSistema {
    return {
      codigo,
      nombre,
      descripcion,
      icono,
      color,
      permisos: [...(ROLE_PERMISSIONS[codigo] || [])],
    };
  }
}
