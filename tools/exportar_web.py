"""Exporta DW_NotariaLozano a web/datos.js (window.DATOS) para el dashboard web animado.
Exporta filas a nivel de hecho (compactas, como arreglos) y los catálogos de dimensiones;
la web calcula los indicadores con las mismas definiciones que las medidas DAX.
Uso:  python -I tools/exportar_web.py
"""
import json
import os
import subprocess

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SALIDA = os.path.join(RAIZ, "web", "datos.js")


def consulta(sql):
    out = subprocess.run(["sqlcmd", "-S", r".\SQLEXPRESS", "-E", "-C", "-b", "-d", "DW_NotariaLozano", "-W", "-h", "-1",
                          "-s", "\t", "-f", "65001", "-Q", "SET NOCOUNT ON; " + sql],
                         capture_output=True, check=True).stdout.decode("utf-8")
    filas = []
    for linea in out.splitlines():
        if linea.strip():
            filas.append([conv(v) for v in linea.split("\t")])
    return filas


def conv(v):
    v = v.strip()
    if v == "NULL":
        return None
    try:
        return int(v)
    except ValueError:
        try:
            return float(v)
        except ValueError:
            return v


def main():
    dims = {
        "servicio": consulta("SELECT ID_Servicio, Nombre_Tramite, Categoria FROM DIM_SERVICIO ORDER BY 1"),
        "personal": consulta("SELECT ID_Personal, Nombre_Completo, Cargo FROM DIM_PERSONAL ORDER BY 1"),
        "cliente": consulta("SELECT ID_Cliente, Razon_Social_Nombre, Tipo_Cliente, Distrito, Segmento FROM DIM_CLIENTE ORDER BY 1"),
        "metodo": consulta("SELECT ID_Metodo, Tipo_Pago, Canal FROM DIM_METODO_PAGO ORDER BY 1"),
        "etapa": consulta("SELECT ID_Etapa, Nombre_Etapa FROM DIM_ETAPA_TRAMITE ORDER BY Orden"),
        "turno": consulta("SELECT ID_Turno, Nombre_Turno FROM DIM_TURNO ORDER BY 1"),
        "tipodoc": consulta("SELECT ID_TipoDocumento, Nombre_TipoDocumento FROM DIM_TIPO_DOCUMENTO ORDER BY 1"),
        "notario": consulta("SELECT ID_Notario, Nombre_Completo, Rol FROM DIM_NOTARIO ORDER BY 1"),
        "estadopago": consulta("SELECT ID_Estado_Pago, Estado FROM DIM_ESTADO_PAGO ORDER BY 1"),
        "tiempo": consulta("SELECT ID_Tiempo, Anio_Mes, Mes_Etiqueta, Trimestre_Texto, Nombre_Dia, Dia_Semana FROM DIM_TIEMPO ORDER BY 1"),
    }
    hechos = {
        # nro, tiempo, servicio, notario, cliente, personal, estado_pago, monto_pagado, monto_arancel, estado_tramite, dias, turno, metodo
        "tramites": consulta("SELECT Nro_Tramite, ID_Tiempo, ID_Servicio, ID_Notario, ID_Cliente, ID_Personal, ID_Estado_Pago, "
                             "Monto_Pagado, Monto_Arancel, Estado_Tramite, Dias_Duracion, ID_Turno, ID_Metodo FROM FACT_TRAMITE_GENERAL"),
        # nro, tiempo, servicio, cliente, personal, metodo, cobrado, costo, pendiente, estado_pago, turno, notario
        "pagos": consulta("SELECT Nro_Tramite, ID_Tiempo, ID_Servicio, ID_Cliente, ID_Personal, ID_Metodo, Monto_Cobrado, Costo_Asociado, "
                          "Monto_Pendiente, ID_Estado_Pago, ID_Turno, ID_Notario FROM FACT_TRAMITES_FINANCIEROS"),
        # nro, tiempo, servicio, personal, etapa, turno, espera, proceso, cliente, notario
        "atenciones": consulta("SELECT Nro_Tramite, ID_Tiempo, ID_Servicio, ID_Personal, ID_Etapa, ID_Turno, Minutos_Espera, Minutos_Proceso, "
                               "ID_Cliente, ID_Notario FROM FACT_TIEMPOS_ATENCION"),
        # nro, tiempo, servicio, personal, tipodoc, cliente, cantidad, turno, notario
        "documentos": consulta("SELECT Nro_Tramite, ID_Tiempo, ID_Servicio, ID_Personal, ID_TipoDocumento, ID_Cliente, Cantidad_Documentos, "
                               "ID_Turno, ID_Notario FROM FACT_DOCUMENTOS_OTORGADOS"),
    }
    datos = {"generado": "DW_NotariaLozano · 01/06/2026 – 22/11/2026", "dims": dims, "hechos": hechos}
    os.makedirs(os.path.dirname(SALIDA), exist_ok=True)
    with open(SALIDA, "w", encoding="utf-8") as fh:
        fh.write("window.DATOS = ")
        json.dump(datos, fh, ensure_ascii=False, separators=(",", ":"))
        fh.write(";\n")
    print(f"{SALIDA}: " + ", ".join(f"{k}={len(v)}" for k, v in hechos.items()) + f" ({os.path.getsize(SALIDA) // 1024} KB)")


if __name__ == "__main__":
    main()
