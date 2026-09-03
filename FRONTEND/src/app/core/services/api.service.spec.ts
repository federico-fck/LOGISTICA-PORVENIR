import { HttpClient, provideHttpClient } from '@angular/common/http';
import {
  HttpTestingController,
  provideHttpClientTesting,
} from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { environment } from '../../../environments/environment';
import { ApiService } from './api.service';

describe('ApiService', () => {
  let service: ApiService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [ApiService, provideHttpClient(), provideHttpClientTesting()],
    });

    service = TestBed.inject(ApiService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
    TestBed.resetTestingModule();
  });

  it('realiza GET con URL base y omite parametros vacios', () => {
    let respuesta: unknown;

    service
      .get('insumos', {
        busqueda: 'casco',
        estado: '',
        nulo: null,
        indefinido: undefined,
        pagina: 2,
      })
      .subscribe((data) => {
        respuesta = data;
      });

    const request = httpMock.expectOne((req) => {
      return (
        req.url === `${environment.apiUrl}/insumos` &&
        req.params.get('busqueda') === 'casco' &&
        req.params.get('pagina') === '2' &&
        !req.params.has('estado') &&
        !req.params.has('nulo') &&
        !req.params.has('indefinido')
      );
    });

    expect(request.request.method).toBe('GET');
    request.flush([{ idInsumo: 1 }]);
    expect(respuesta).toEqual([{ idInsumo: 1 }]);
  });

  it('realiza POST, PATCH y DELETE contra el endpoint esperado', () => {
    const body = { nombre: 'Almacen Central' };

    service.post('almacenes', body).subscribe();
    let request = httpMock.expectOne(`${environment.apiUrl}/almacenes`);
    expect(request.request.method).toBe('POST');
    expect(request.request.body).toBe(body);
    request.flush({});

    service.patch('almacenes/3', body).subscribe();
    request = httpMock.expectOne(`${environment.apiUrl}/almacenes/3`);
    expect(request.request.method).toBe('PATCH');
    expect(request.request.body).toBe(body);
    request.flush({});

    service.delete('almacenes/3').subscribe();
    request = httpMock.expectOne(`${environment.apiUrl}/almacenes/3`);
    expect(request.request.method).toBe('DELETE');
    request.flush({});
  });
});

describe('ApiService provider', () => {
  it('puede inyectarse junto a HttpClient sin llamadas reales', () => {
    TestBed.configureTestingModule({
      providers: [ApiService, provideHttpClient(), provideHttpClientTesting()],
    });

    expect(TestBed.inject(ApiService)).toBeTruthy();
    expect(TestBed.inject(HttpClient)).toBeTruthy();
  });
});
