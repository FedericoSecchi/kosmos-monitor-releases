# Kosmos Monitor

Un monitor liviano para la barra de menú de la Mac. Te dice si la Mac está exigida (memoria, procesador, calor),
cuánta energía gasta y qué conviene hacer, con avisos que tienen un botón para hacerlo. Reconoce sola la Mac donde
está instalada: no hay nada que configurar.

Este repositorio solo tiene el instalador y las versiones publicadas (la app ya compilada). No tiene el código fuente.

## Requisitos

- Mac con chip de Apple (M1, M2, M3, M4…). No funciona en Macs con procesador Intel.
- macOS 13 Ventura o más nuevo.

## Instalar o actualizar

Abrí la app **Terminal** (en Aplicaciones › Utilidades), pegá esta línea y apretá Enter:

```
curl -fsSL https://raw.githubusercontent.com/FedericoSecchi/kosmos-monitor-releases/main/install.sh | bash
```

Descarga la última versión, verifica su firma, la instala en tu carpeta Aplicaciones (sin pedir contraseña) y la
abre. Si ya la tenías, la actualiza y te lo dice. No toca tus datos ni tus preferencias.

La primera vez se abre una bienvenida que muestra qué Mac detectó, qué va a vigilar y qué puede pedirte (avisos,
plan de Claude, Modo bajo consumo sin contraseña). Todo es opcional y se cambia después en Opciones.

## Qué datos lee

Todo se lee y se queda en tu Mac:

- Del sistema: uso del procesador y de la memoria, swap, temperatura y consumo del chip, batería y cargador, qué
  apps gastan energía y cuál no deja dormir a la Mac.
- Nada sale de la Mac, salvo una cosa opcional y apagada hasta que la actives: si usás Claude Code y conectás tu
  plan de Claude, la app lee la credencial de Claude Code del Llavero (solo lectura) para consultar tu uso a
  `api.anthropic.com`. Nunca se envía a otro lado.

Los datos quedan en `~/Library/Application Support/Kosmos Monitor`.

## Desinstalar

1. Si activaste «Modo bajo consumo sin contraseña»: en el panel › engranaje › Opciones › Modo bajo consumo ›
   **Quitar permiso**.
2. Panel › engranaje › Opciones › **Salir de Kosmos Monitor**.
3. Arrastrá **Kosmos Monitor** desde Aplicaciones (o tu carpeta Aplicaciones personal) a la Papelera.
4. Opcional, para borrar también sus datos: la carpeta `~/Library/Application Support/Kosmos Monitor`.

Incluye macmon (licencia MIT, © vladkens) para leer el consumo por componente del chip.
