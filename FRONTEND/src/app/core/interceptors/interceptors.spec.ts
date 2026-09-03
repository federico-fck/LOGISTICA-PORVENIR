import { HttpClient, provideHttpClient, withInterceptors } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';

import { ConfirmacionAccionService } from '../feedback/confirmacion-accion.service';
import { AuthState } from '../state/auth.state';
import { authInterceptor } from './auth.interceptor';
import { confirmacionAccionInterceptor } from './confirmacion-accion.interceptor';

describe('authInterceptor', () => {
  let http: HttpClient;
  let httpMock: HttpTestingController;
  let authState: {
    token: ReturnType<typeof vi.fn>;
    cerrarSesion: ReturnType<typeof vi.fn>;
  };
  let router: { navigate: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    authState = {
      token: vi.fn(() => 'abc123'),
      cerrarSesion: vi.fn(),
    };
    router = { navigate: vi.fn() };
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([authInterceptor])),
        provideHttpClientTesting(),
        { provide: AuthState, useValue: authState },
        { provide: Router, useValue: router },
      ],
    });

    http = TestBed.inject(HttpClient);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
    TestBed.resetTestingModule();
  });

  it('agrega Authorization cuando existe token', () => {
    http.get('/api/seguro').subscribe();

    const request = httpMock.expectOne('/api/seguro');
    expect(request.request.headers.get('Authorization')).toBe('Bearer abc123');
    request.flush({});
  });

  it('no agrega Authorization cuando no existe token', () => {
    authState.token.mockReturnValue(null);

    http.get('/api/publico').subscribe();

    const request = httpMock.expectOne('/api/publico');
    expect(request.request.headers.has('Authorization')).toBe(false);
    request.flush({});
  });

  it('cierra sesion y redirige al recibir 401', () => {
    let errorStatus = 0;

    http.get('/api/protegido').subscribe({
      error: (error) => {
        errorStatus = error.status;
      },
    });

    const request = httpMock.expectOne('/api/protegido');
    request.flush({ message: 'Unauthorized' }, { status: 401, statusText: 'Unauthorized' });

    expect(errorStatus).toBe(401);
    expect(authState.cerrarSesion).toHaveBeenCalledTimes(1);
    expect(router.navigate).toHaveBeenCalledWith(['/login']);
  });
});

describe('confirmacionAccionInterceptor', () => {
  let http: HttpClient;
  let httpMock: HttpTestingController;
  let confirmacionService: { mostrar: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    confirmacionService = { mostrar: vi.fn() };
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(withInterceptors([confirmacionAccionInterceptor])),
        provideHttpClientTesting(),
        { provide: ConfirmacionAccionService, useValue: confirmacionService },
      ],
    });

    http = TestBed.inject(HttpClient);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
    TestBed.resetTestingModule();
  });

  it('ignora metodos de lectura y login', () => {
    http.get('/api/almacenes').subscribe();
    httpMock.expectOne('/api/almacenes').flush([]);

    http.post('/api/auth/login', { usuario: 'admin' }).subscribe();
    httpMock.expectOne('/api/auth/login').flush({});

    expect(confirmacionService.mostrar).not.toHaveBeenCalled();
  });

  it('muestra mensaje especifico para acciones conocidas', () => {
    http.patch('/api/pedidos/5/aprobar', {}).subscribe();
    httpMock.expectOne('/api/pedidos/5/aprobar').flush({});

    http.delete('/api/inventario-despachos/despachos/9').subscribe();
    httpMock.expectOne('/api/inventario-despachos/despachos/9').flush({});

    expect(confirmacionService.mostrar).toHaveBeenCalledWith(
      'Pedido aprobado correctamente.',
    );
    expect(confirmacionService.mostrar).toHaveBeenCalledWith(
      'Despacho eliminado correctamente.',
    );
  });

  it('usa mensaje por entidad para creacion y actualizacion', () => {
    http.post('/api/proveedores', { razonSocial: 'Proveedor' }).subscribe();
    httpMock.expectOne('/api/proveedores').flush({});

    http.patch('/api/almacenes/1', { nombreAlmacen: 'Central' }).subscribe();
    httpMock.expectOne('/api/almacenes/1').flush({});

    expect(confirmacionService.mostrar).toHaveBeenCalledWith(
      'Proveedor creado correctamente.',
    );
    expect(confirmacionService.mostrar).toHaveBeenCalledWith(
      'Almacen actualizado correctamente.',
    );
  });
});
