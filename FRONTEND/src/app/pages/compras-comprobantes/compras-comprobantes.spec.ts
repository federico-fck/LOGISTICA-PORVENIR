import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { AlmacenesService } from '../../core/services/almacenes.service';
import { ComprasComprobantesService } from '../../core/services/compras-comprobantes.service';
import { InsumosService } from '../../core/services/insumos.service';
import { PedidosService } from '../../core/services/pedidos.service';
import { ProveedoresService } from '../../core/services/proveedores.service';
import { AuthState } from '../../core/state/auth.state';
import { validarArchivoRecepcion } from '../../core/forms/professional-forms';
import { ComprasComprobantes } from './compras-comprobantes';

describe('Compras/Recepciones - archivo de respaldo', () => {
  function crearComponente(): ComprasComprobantes {
    TestBed.configureTestingModule({
      imports: [ComprasComprobantes],
      providers: [
        {
          provide: ComprasComprobantesService,
          useValue: {
            ordenesCompra: () => of([]),
            recepciones: () => of([]),
            comprobantes: () => of([]),
          },
        },
        { provide: PedidosService, useValue: { listar: () => of([]) } },
        { provide: ProveedoresService, useValue: { listar: () => of([]) } },
        { provide: InsumosService, useValue: { listar: () => of([]) } },
        { provide: AlmacenesService, useValue: { listar: () => of([]) } },
        { provide: AuthState, useValue: { usuario: signal({ idUsuario: 1 }) } },
      ],
    });

    return TestBed.createComponent(ComprasComprobantes).componentInstance;
  }

  function eventoArchivo(nombre: string): Event {
    return {
      target: {
        files: [new File(['contenido'], nombre)],
        value: nombre,
      },
    } as unknown as Event;
  }

  it('archivo PDF/JPG/JPEG/PNG es valido', () => {
    expect(validarArchivoRecepcion('guia-recepcion.pdf')).toBe(true);
    expect(validarArchivoRecepcion('foto.jpg')).toBe(true);
    expect(validarArchivoRecepcion('foto.jpeg')).toBe(true);
    expect(validarArchivoRecepcion('evidencia.png')).toBe(true);
  });

  it('archivo EXE es invalido', () => {
    expect(validarArchivoRecepcion('instalador.exe')).toBe(false);
  });

  it('muestra el nombre del archivo seleccionado', () => {
    const componente = crearComponente();

    componente.cambiarArchivoRecepcion(eventoArchivo('guia-recepcion.pdf'));

    expect(componente.archivoRecepcion()).toBe('guia-recepcion.pdf');
    expect(componente.formRecepcion.controls.archivoRespaldo.value).toBe(
      'guia-recepcion.pdf',
    );
    expect(componente.archivoRecepcionError()).toBe('');
  });

  it('limpia archivo y muestra mensaje si el formato no esta permitido', () => {
    const componente = crearComponente();
    const evento = eventoArchivo('instalador.exe');

    componente.cambiarArchivoRecepcion(evento);

    expect((evento.target as HTMLInputElement).value).toBe('');
    expect(componente.archivoRecepcion()).toBe('');
    expect(componente.formRecepcion.controls.archivoRespaldo.value).toBe('');
    expect(componente.archivoRecepcionError()).toBe(
      'Formato no permitido. Use PDF, JPG, JPEG o PNG.',
    );
  });
});
