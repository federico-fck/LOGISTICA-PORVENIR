import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { of, Subject, throwError } from 'rxjs';

import { AuthService } from '../core/services/auth.service';
import { AuditoriaService } from '../core/services/auditoria.service';
import { MenuService } from '../core/services/menu.service';
import { NotificacionesService } from '../core/services/notificaciones.service';
import { PermissionService } from '../core/services/permission.service';
import { UsuariosService } from '../core/services/usuarios.service';
import { AuthState } from '../core/state/auth.state';
import { AdminLayout } from '../layouts/admin-layout/admin-layout';
import { Navbar } from '../layouts/admin-layout/navbar/navbar';
import { Auditoria } from './auditoria/auditoria';
import { Notificaciones } from './notificaciones/notificaciones';
import { Perfil } from './perfil/perfil';
import { RolesPermisos } from './roles-permisos/roles-permisos';

describe('Notificaciones page', () => {
  let service: {
    listar: ReturnType<typeof vi.fn>;
    buscarPorId: ReturnType<typeof vi.fn>;
    marcarComoLeida: ReturnType<typeof vi.fn>;
    marcarTodasComoLeidas: ReturnType<typeof vi.fn>;
    eliminar: ReturnType<typeof vi.fn>;
    notificarCambio: ReturnType<typeof vi.fn>;
  };
  let permissionService: {
    tienePermiso: ReturnType<typeof vi.fn>;
    mensajeSinPermiso: string;
  };
  let alertSpy: ReturnType<typeof vi.spyOn>;

  function crearComponente(tienePermiso = true) {
    service = {
      listar: vi.fn(() => of({ data: [] })),
      buscarPorId: vi.fn((id: number) => of({ idNotificacion: id, titulo: 'Detalle' })),
      marcarComoLeida: vi.fn(() => of({})),
      marcarTodasComoLeidas: vi.fn(() => of({})),
      eliminar: vi.fn(() => of({})),
      notificarCambio: vi.fn(),
    };
    permissionService = {
      tienePermiso: vi.fn(() => tienePermiso),
      mensajeSinPermiso: 'Sin permiso',
    };
    alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});

    TestBed.configureTestingModule({
      providers: [
        { provide: NotificacionesService, useValue: service },
        { provide: PermissionService, useValue: permissionService },
      ],
    });

    return TestBed.runInInjectionContext(() => new Notificaciones());
  }

  afterEach(() => {
    alertSpy?.mockRestore();
    TestBed.resetTestingModule();
  });

  it('calcula totales y filtra por estado, texto y prioridad', () => {
    const component = crearComponente();
    component.notificaciones.set([
      {
        idNotificacion: 1,
        titulo: 'Stock bajo',
        mensaje: 'Casco sin stock',
        tipoNotificacion: 'STOCK_CRITICO',
        prioridad: 'URGENTE',
        leida: false,
        estado: 'PENDIENTE',
      } as any,
      {
        idNotificacion: 2,
        titulo: 'Pedido aprobado',
        mensaje: 'Listo',
        tipoNotificacion: 'PEDIDO',
        prioridad: 'NORMAL',
        estado: 'LEIDA',
      } as any,
    ]);

    expect(component.totalNotificaciones()).toBe(2);
    expect(component.totalNoLeidas()).toBe(1);
    expect(component.totalLeidas()).toBe(1);
    expect(component.totalUrgentes()).toBe(1);

    component.cambiarFiltro('no-leidas');
    component.busqueda.set('casco');

    expect(component.notificacionesFiltradas().map((n) => component.idNotificacion(n))).toEqual([
      1,
    ]);
  });

  it('marca notificacion como leida y emite cambio local', () => {
    const component = crearComponente();
    component.notificaciones.set([
      { id_notificacion: 8, titulo: 'Nueva', estado: 'NO_LEIDA' } as any,
    ]);
    component.notificacionSeleccionada.set(component.notificaciones()[0]);

    component.marcarLeida(component.notificaciones()[0]);

    expect(service.marcarComoLeida).toHaveBeenCalledWith(8);
    expect(component.notificaciones()[0].estado).toBe('LEIDA');
    expect(component.notificacionSeleccionada()?.estado).toBe('LEIDA');
    expect(component.mensaje()).toBe('Notificación marcada como leída.');
    expect(service.notificarCambio).toHaveBeenCalledTimes(1);
  });

  it('marca todas como leidas y evita accion sin permiso', () => {
    const component = crearComponente();
    component.notificaciones.set([
      { idNotificacion: 1, leida: false, estado: 'PENDIENTE' } as any,
      { idNotificacion: 2, estadoNotificacion: 'PENDIENTE' } as any,
    ]);

    component.marcarTodasLeidas();

    expect(service.marcarTodasComoLeidas).toHaveBeenCalledTimes(1);
    expect(component.totalNoLeidas()).toBe(0);

    permissionService.tienePermiso.mockReturnValue(false);
    component.marcarLeida({ idNotificacion: 1 } as any);

    expect(permissionService.tienePermiso).toHaveBeenCalledWith(
      'notificaciones.marcar_leida',
    );
    expect(alertSpy).toHaveBeenCalledWith('Sin permiso');
  });

  it('abre detalle con fallback y elimina localmente', () => {
    service = undefined as any;
    const component = crearComponente();
    service.buscarPorId.mockReturnValueOnce(throwError(() => new Error('404')));
    const item = { idNotificacion: 4, titulo: 'Local' } as any;
    component.notificaciones.set([item]);

    component.abrirVer(item);
    expect(component.notificacionSeleccionada()).toBe(item);
    expect(component.modoModal()).toBe('ver');

    component.abrirEliminar(item);
    component.confirmarEliminar();

    expect(service.eliminar).toHaveBeenCalledWith(4);
    expect(component.notificaciones()).toEqual([]);
    expect(component.modoModal()).toBe('ninguno');
  });
});

describe('Auditoria page', () => {
  let auditoriaService: {
    listar: ReturnType<typeof vi.fn>;
    tipos: ReturnType<typeof vi.fn>;
    resumen: ReturnType<typeof vi.fn>;
  };
  let permissionService: {
    tienePermiso: ReturnType<typeof vi.fn>;
    mensajeSinPermiso: string;
  };
  let alertSpy: ReturnType<typeof vi.spyOn>;

  function crearComponente(tienePermiso = true) {
    auditoriaService = {
      listar: vi.fn(() => of([])),
      tipos: vi.fn(() => of({ tiposAccion: ['CREAR'], modulos: ['usuarios'] })),
      resumen: vi.fn(() => of({ totalRegistros: 1 })),
    };
    permissionService = {
      tienePermiso: vi.fn(() => tienePermiso),
      mensajeSinPermiso: 'Sin permiso',
    };
    alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {});

    TestBed.configureTestingModule({
      providers: [
        { provide: AuditoriaService, useValue: auditoriaService },
        { provide: PermissionService, useValue: permissionService },
      ],
    });

    return TestBed.runInInjectionContext(() => new Auditoria());
  }

  afterEach(() => {
    alertSpy?.mockRestore();
    TestBed.resetTestingModule();
  });

  it('carga filtros, resumen y auditoria con parametros seleccionados', () => {
    const component = crearComponente();
    component.tipoSeleccionado.set('CREAR');
    component.moduloSeleccionado.set('usuarios');
    component.fechaInicio.set('2026-08-01');
    component.fechaFin.set('2026-08-15');

    component.cargarDatosIniciales();

    expect(auditoriaService.tipos).toHaveBeenCalledTimes(1);
    expect(auditoriaService.resumen).toHaveBeenCalledTimes(1);
    expect(auditoriaService.listar).toHaveBeenCalledWith({
      tipoAccion: 'CREAR',
      moduloAfectado: 'usuarios',
      fechaInicio: '2026-08-01',
      fechaFin: '2026-08-15',
    });
    expect(component.tiposAccion()).toEqual(['CREAR']);
    expect(component.modulos()).toEqual(['usuarios']);
  });

  it('filtra auditorias y calcula totales por tipo', () => {
    const component = crearComponente();
    component.auditorias.set([
      {
        idAuditoria: 1,
        tipoAccion: 'CREAR',
        accionRealizada: 'Crear usuario',
        moduloAfectado: 'usuarios',
        tablaAfectada: 'usuarios',
        direccionIp: '127.0.0.1',
        usuario: { nombreCompleto: 'Ana' },
      } as any,
      {
        idAuditoria: 2,
        tipoAccion: 'ELIMINAR',
        accionRealizada: 'Eliminar almacen',
        moduloAfectado: 'almacenes',
      } as any,
    ]);

    component.busqueda.set('ana');

    expect(component.totalRegistros()).toBe(2);
    expect(component.totalCrear()).toBe(1);
    expect(component.totalEliminar()).toBe(1);
    expect(component.auditoriasFiltradas()).toHaveLength(1);
  });

  it('abre detalle solo con permiso y formatea valores de auditoria', () => {
    const component = crearComponente(false);
    const item = { tipoAccion: 'CREAR', tablaAfectada: 'usuarios' } as any;

    component.abrirDetalle(item);

    expect(component.detalleAbierto()).toBe(false);
    expect(component.error()).toBe('Sin permiso');
    expect(alertSpy).toHaveBeenCalledWith('Sin permiso');

    permissionService.tienePermiso.mockReturnValue(true);
    component.abrirDetalle(item);
    expect(component.detalleAbierto()).toBe(true);
    expect(component.etiquetaTipo('REGISTRAR_COMPRA')).toBe('Registrar compra');
    expect(component.jsonTexto(null)).toBe('Sin datos');
    expect(component.filasRegistroAnteriorAuditoria(item)[0].campo).toBe(
      'Tabla afectada',
    );
  });
});

describe('RolesPermisos page', () => {
  afterEach(() => {
    TestBed.resetTestingModule();
  });

  it('carga usuarios, filtra roles y cuenta usuarios activos por rol', () => {
    const usuariosService = {
      listar: vi.fn(() =>
        of({
          data: [
            {
              nombreUsuario: 'admin',
              estado: 'ACTIVO',
              rol: { nombreRol: 'Administrador' },
            },
            {
              nombreUsuario: 'auditor',
              estadoUsuario: 'BLOQUEADO',
              codigoRol: 'AUDITOR',
            },
          ],
        }),
      ),
    };
    TestBed.configureTestingModule({
      providers: [{ provide: UsuariosService, useValue: usuariosService }],
    });
    const component = TestBed.runInInjectionContext(() => new RolesPermisos());

    component.cargarUsuarios();
    component.busqueda.set('auditor');

    expect(component.usuarios()).toHaveLength(2);
    expect(component.totalRoles()).toBeGreaterThan(0);
    expect(component.totalUsuarios()).toBe(2);
    expect(component.totalUsuariosActivos()).toBe(1);
    expect(component.rolesFiltrados().map((rol) => rol.codigo)).toContain('AUDITOR');
    expect(component.usuariosPorRol('ADMINISTRADOR')).toBe(1);
  });
});

describe('Perfil page', () => {
  afterEach(() => {
    TestBed.resetTestingModule();
  });

  it('calcula iniciales, documento y estado del usuario actual', () => {
    const usuario = signal<any>({
      idUsuario: 1,
      nombreUsuario: 'ana',
      nombreCompleto: 'Ana Rojas',
      cedulaIdentidad: '123-1A LP',
      telefono: '70000000',
      cargo: 'Jefe',
      estado: 'ACTIVO',
      area: { nombreArea: 'Mina Norte' },
    });
    TestBed.configureTestingModule({
      providers: [
        {
          provide: AuthState,
          useValue: {
            usuario,
            rolNombreActual: signal('Jefe de area'),
          },
        },
        { provide: AuthService, useValue: { perfil: vi.fn(() => of({})) } },
      ],
    });
    const component = TestBed.runInInjectionContext(() => new Perfil());

    expect(component.iniciales()).toBe('AR');
    expect(component.documento(usuario())).toBe('123-1A LP');
    expect(component.area(usuario())).toBe('Mina Norte');
    expect(component.claseEstado(usuario())).toBe('text-green-700');
  });

  it('actualiza perfil y muestra error si falla', () => {
    const usuario = signal<any>({ nombreUsuario: 'ana', estado: 'ACTIVO' });
    const authService = {
      perfil: vi.fn(() => throwError(() => new Error('fallo'))),
    };
    TestBed.configureTestingModule({
      providers: [
        {
          provide: AuthState,
          useValue: {
            usuario,
            rolNombreActual: signal('Sin rol'),
          },
        },
        { provide: AuthService, useValue: authService },
      ],
    });
    const component = TestBed.runInInjectionContext(() => new Perfil());

    component.cargarPerfil();

    expect(component.cargando()).toBe(false);
    expect(component.error()).toBe('No se pudo actualizar la información del perfil.');
  });
});

describe('AdminLayout y Navbar', () => {
  afterEach(() => {
    localStorage.clear();
    TestBed.resetTestingModule();
  });

  it('AdminLayout carga notificaciones, responde cambios y cierra sesion', () => {
    const cambios$ = new Subject<void>();
    const usuario = signal<any>({ idUsuario: 5, nombreCompleto: 'Ana Rojas' });
    const notificacionesService = {
      cambios$: cambios$.asObservable(),
      listar: vi.fn(() =>
        of([
          { idNotificacion: 1, leida: false, estado: 'PENDIENTE' },
          { idNotificacion: 2, leida: true },
        ]),
      ),
    };
    const authService = { logout: vi.fn() };
    const router = { navigate: vi.fn() };
    TestBed.configureTestingModule({
      providers: [
        { provide: AuthService, useValue: authService },
        {
          provide: AuthState,
          useValue: {
            usuario,
            rolNombreActual: signal('Administrador'),
          },
        },
        { provide: MenuService, useValue: { obtenerMenu: vi.fn(() => []) } },
        { provide: NotificacionesService, useValue: notificacionesService },
        { provide: Router, useValue: router },
      ],
    });
    const component = TestBed.runInInjectionContext(() => new AdminLayout());

    component.ngOnInit();
    cambios$.next();
    component.alternarMenuUsuario();
    component.irPerfil();
    component.cerrarSesion();

    expect(notificacionesService.listar).toHaveBeenCalledWith({ idUsuario: 5 });
    expect(notificacionesService.listar).toHaveBeenCalledTimes(2);
    expect(component.totalNoLeidas()).toBe(1);
    expect(component.iniciales()).toBe('AR');
    expect(authService.logout).toHaveBeenCalledTimes(1);
    expect(router.navigate).toHaveBeenCalledWith(['/perfil']);
    expect(router.navigate).toHaveBeenCalledWith(['/login']);
  });

  it('Navbar obtiene usuario, notificaciones y navega desde acciones publicas', () => {
    const router = { navigate: vi.fn() };
    const authState = {
      usuario: signal<any>({ nombreCompleto: 'Luis Perez' }),
      rolNombreActual: signal('Encargado'),
      cerrarSesion: vi.fn(),
    };
    const notificacionesService = {
      listar: vi.fn(() =>
        of({
          items: [
            { idNotificacion: 1, visto: false },
            { idNotificacion: 2, visto: true },
          ],
        }),
      ),
    };
    TestBed.configureTestingModule({
      providers: [
        { provide: Router, useValue: router },
        { provide: AuthState, useValue: authState },
        { provide: NotificacionesService, useValue: notificacionesService },
      ],
    });
    const component = TestBed.runInInjectionContext(() => new Navbar());

    component.cargarNotificaciones();
    component.alternarMenuUsuario();
    component.irNotificaciones();
    component.irPerfil();
    component.cerrarSesion();

    expect(component.nombreUsuario()).toBe('Luis Perez');
    expect(component.iniciales()).toBe('LP');
    expect(component.totalNoLeidas()).toBe(1);
    expect(router.navigate).toHaveBeenCalledWith(['/notificaciones']);
    expect(router.navigate).toHaveBeenCalledWith(['/perfil']);
    expect(router.navigate).toHaveBeenCalledWith(['/login']);
    expect(authState.cerrarSesion).toHaveBeenCalledTimes(1);
  });
});
