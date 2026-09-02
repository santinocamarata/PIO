# PIO — Fichas de excepción

Aplicación de mesa de entrada para registrar alumnos inscriptos que no podrán
asistir a la fecha de curso asignada, y emitir la ficha de excepción
correspondiente.

La aplicación tiene **dos vistas** que se alternan desde la barra superior:
**Fichas** (el listado, con filtros) y **Nueva ficha** (el formulario de alta).

Las fichas, los motivos, las fechas y los PDF adjuntos viven en **Supabase**:
lo que se carga en un puesto se ve en todos los demás. En producción corre en
Vercel: <https://pio-t9ma.vercel.app>

## Acceso

| Usuario | Contraseña | Rol | Qué puede hacer |
|---|---|---|---|
| `ingreso` | `UADE2026` | Operador | Cargar y consultar fichas |
| `aromero` | `lordalan` | Admin | Todo lo anterior + configuración y borrado |
| `scamarata` | `lordalan` | Admin | Todo lo anterior + configuración y borrado |

El nombre de usuario no distingue mayúsculas de minúsculas; la contraseña sí,
exacta. La sesión vive en `sessionStorage`: se cierra al cerrar el navegador.
En un equipo compartido conviene usar **Salir** al terminar.

> ### Esto no es seguridad, es separación de roles
>
> Las contraseñas están escritas en `index.html` y se verifican en el navegador.
> Cualquiera que abra el archivo con un editor de texto, o que use el inspector
> del navegador, las ve y puede saltear la pantalla de ingreso. **No hay forma de
> evitarlo sin un servidor.**
>
> Sirve para que un operador no toque la configuración por error y para dejar
> registrado quién emitió cada ficha. No sirve para impedir el acceso de alguien
> que quiera entrar. Hasta que esté Supabase Auth —que valida contra el servidor
> y refuerza los permisos con RLS en Postgres— no guardes en esta aplicación
> nada cuya fuga sea un problema.

Para cambiar las credenciales, editá el arreglo `USUARIOS` al principio del
bloque `<script>` de `index.html`.

## Cómo se usa

En producción, abrí <https://pio-t9ma.vercel.app>. En local, abrí `index.html`
en el navegador: no requiere instalación, servidor ni build.

### Vista Fichas

Cada fila muestra legajo, alumno, motivo, fecha de recuperatorio, la
documentación adjunta y el número de ficha.

- El botón con el nombre del PDF **abre el archivo** en una pestaña nueva, con
  una URL firmada de Supabase que vence a la hora.
- **Imprimir** vuelve a emitir esa ficha, con firma y sello, en cualquier momento.
- **Eliminar** borra la ficha y su PDF. Solo lo ve el admin; está para limpiar
  fichas de prueba, no es parte del circuito normal.
- **Exportar CSV** baja el listado tal como está filtrado, incluyendo qué usuario
  emitió cada ficha.
- **Exportar carpetas** baja un ZIP con la documentación, agrupada por fecha.

### Exportar carpetas

Arma un ZIP con una carpeta por fecha de recuperatorio y, adentro de cada una,
los PDF de las fichas de esa fecha:

```
documentacion-recuperatorios-2026-09-02.zip
├── 2026-09-29/
│   ├── 1251113 - certificado medico.pdf
│   └── 1248471 - constancia laboral.pdf
└── 2026-10-13/
    └── 1247358 - pasajes.pdf
```

**Las carpetas se nombran en ISO (`2026-09-29`), no en `29/09/2026`.** Es el
único formato en el que el orden alfabético del explorador de archivos coincide
con el orden del calendario: con `dd/mm/aaaa`, el `13/10` quedaría antes que el
`29/09`.

Cada archivo lleva el legajo adelante, porque dos alumnos distintos suben
seguido un `certificado.pdf`. Si aun así hay dos nombres iguales en la misma
carpeta, el segundo se desambigua con el número de ficha.

El ZIP se arma con **las fichas que estás viendo**, igual que el CSV: si querés
solo una fecha, filtrala primero. Las fichas sin adjunto no generan carpeta.
El compresor se descarga de internet la primera vez que se usa el botón.

### Filtros

Cinco criterios que se combinan con Y: **Alumno** y **Legajo** buscan por
coincidencia parcial; **Motivo** y **Recuperatorio** son exactos; **Estado**
separa vigentes de vencidas según la fecha de recuperatorio.

Los selectores de motivo y fecha se arman con los valores que realmente
aparecen en las fichas, así ninguna opción devuelve cero resultados.
**Limpiar filtros** vuelve al listado completo.

### Vista Nueva ficha

1. **Legajo** — escribí los 7 dígitos. Se valida contra el padrón en el momento:
   la barra de color y el mensaje debajo indican si el legajo existe, está
   incompleto o no figura. Cuando es válido aparece el nombre del alumno.
2. **Motivo** — seleccionalo de la lista.
3. **Fecha de recuperatorio** — solo aparecen las vigentes.
4. **Documentación** — PDF opcional, hasta 10 MB. Se valida formato y tamaño.
5. **Guardar ficha** — vuelve al listado con la ficha nueva destacada.

El botón Guardar se habilita solo cuando el legajo es válido y están elegidos el
motivo y la fecha. **Cancelar** vuelve al listado sin guardar.

## Configuración (solo admin)

Botón **Configuración** en la barra superior. Tiene tres secciones:

**Motivos de excepción.** Agregar, activar/desactivar y eliminar. Un motivo
desactivado deja de ofrecerse en las fichas nuevas pero sigue en la lista y las
fichas viejas lo conservan. No admite dos motivos con el mismo texto.

**Fechas de recuperatorio.** Igual que los motivos. Las fechas vencidas quedan
marcadas y no se ofrecen, aunque estén activas. El listado se ordena
cronológicamente.

**Padrón de alumnos.** Cargar el Excel que exporta el sistema académico, con
columnas `legajo` y `alumno`. Acepta `.xlsx`, `.xls` y `.csv`.

> **Desactivar es más seguro que eliminar.** Las fichas guardan el texto del
> motivo y la fecha, no una referencia, así que eliminar no rompe el historial —
> pero desactivar deja registro de que ese motivo existió.

La lectura de Excel usa una librería que se descarga de internet la primera vez;
sin conexión, guardá el archivo como CSV desde Excel y cargá ese.

Para regenerar el padrón que viene embebido por defecto:

```bash
pip install openpyxl
python build_padron.py "Alumnos_a_ingresar_1757390.xlsx"
```

## Dónde se guardan los datos

| Qué | Dónde | Por qué |
|---|---|---|
| Listado de fichas | Supabase · tabla `fichas` | Compartido entre todos los puestos |
| Motivos | Supabase · tabla `motivos` | El admin lo configura una vez para todos |
| Fechas de recuperatorio | Supabase · tabla `fechas_recuperatorio` | Ídem |
| PDF adjuntos | Supabase Storage · bucket `adjuntos` | Privado; se sirve con URL firmada |
| Padrón de alumnos | `padron.js` + `localStorage` | Solo lectura, no necesita compartirse |
| Sesión abierta | `sessionStorage` | Se cierra con el navegador |

Las fichas y la configuración son **compartidas**: lo que carga un operador en
un puesto lo ve otro operador en otro equipo. El padrón, en cambio, es local a
cada navegador: si el admin lo actualiza en un puesto, hay que repetirlo en los
demás o regenerar `padron.js`.

### Puesta en marcha de la base

`supabase_setup.sql` crea las tres tablas, el bucket y las políticas de RLS.
Se corre **una sola vez** en el SQL Editor del proyecto. Además hay que dar los
permisos de tabla al rol anónimo, que las políticas de RLS por sí solas no
otorgan:

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON public.motivos              TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fechas_recuperatorio TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.fichas               TO anon;
```

Sin ese `GRANT`, cada consulta vuelve con `401 permission denied for table`
aunque la política exista y la clave sea correcta.

La clave que va en `index.html` es la **`anon` en formato JWT** (empieza con
`eyJ`), no la publishable `sb_publishable_…`: el SDK no reconoce ese formato y
todas las llamadas fallan con 401. La `service_role` **nunca** va en el HTML.

## Archivos

| Archivo | Qué es |
|---|---|
| `index.html` | La aplicación completa: acceso, listado, carga, configuración y ficha imprimible |
| `padron.js` | Padrón embebido, generado. No editar a mano |
| `build_padron.py` | Regenera `padron.js` desde un Excel |
| `supabase_setup.sql` | Migración inicial de la base. Correr una sola vez |
| `vercel.json` | Le dice a Vercel que es un sitio estático sin build |

## Verificación

Abrí `index.html?test` (o <https://pio-t9ma.vercel.app/?test>) y mirá la consola
del navegador. Corre las comprobaciones sobre autenticación y permisos, la
configuración de motivos y fechas, la normalización de legajos y nombres, la
resolución contra el padrón, la validación del adjunto, el parseo y la generación
de CSV, el filtrado combinado del listado y el formato de fechas y números de
ficha. Si algo falla, se lanza una excepción con el caso concreto.

## Decisiones que conviene conocer

**El error de acceso nunca dice cuál de los dos campos falló.** "Usuario o
contraseña incorrectos" es el mismo mensaje para un usuario inexistente y para
una contraseña equivocada: distinguirlos revelaría qué usuarios existen.

**`[hidden]` lleva `!important`.** La clase `.acceso` declara `display: grid`, y
una regla de clase del autor le gana al `display: none` que el navegador aplica
al atributo `hidden`. Sin ese `!important`, la pantalla de ingreso quedaba
visible encima de la aplicación después de entrar.

**El legajo se normaliza antes de comparar.** El Excel guarda el legajo como
número y el sistema lo trata como texto. Sin normalizar, `1251113`, `"1251113"` y
`" 1251113 "` son tres valores distintos y la búsqueda falla en silencio.

**El nombre no se parte en nombre y apellido.** El Excel trae un solo campo
`alumno` con formato `"Apellido, Nombre"`, pero alrededor del 8% de las filas
vienen invertidas (`"Jean Pierre Jesús, Tapia Vega"`). Partir por la coma
metería el nombre en el campo apellido en esos casos.

**El CSV entrecomilla las comas aunque el separador sea `;`.** Todos los nombres
del padrón contienen una coma. Sin entrecomillar, el archivo se parte en dos
columnas al abrirlo en un Excel configurado con separador coma.

**Las fechas se comparan como texto ISO, no como objetos `Date`.** `'2026-09-15'`
ordena y compara correctamente carácter por carácter, y evita los corrimientos de
día por zona horaria que aparecen al convertir a `Date` y volver.

**El diálogo usa `<dialog>` nativo**, que ya trae fondo oscuro, foco atrapado y
cierre con Esc. No hay JavaScript propio de accesibilidad que pueda quedar
desincronizado.

**El número de ficha es determinístico**, con formato
`EX-AAAAMMDD-LEGAJO-HHMM`. La columna `folio` tiene un índice único en Postgres,
así que dos puestos no pueden emitir el mismo número; pero sigue sin ser una
secuencia correlativa.

**El error es anaranjado, no rojo.** Con la marca en borgoña, un rojo puro se
lee como color institucional y deja de alertar. El error va a `oklch(0.520 0.155 44)`,
lo bastante lejos en tono como para distinguirse de un botón primario.

**El filtro por Estado arranca en "Todas".** Un filtro que oculta datos por
defecto es una trampa: si el operador carga una ficha con fecha pasada y el
listado arranca en "Vigentes", la ficha desaparece y parece que no se guardó.

**Guardar una ficha limpia los filtros.** Por la misma razón: la ficha recién
creada tiene que verse sí o sí al volver al listado.

## Qué falta para la versión completa

- Autenticación real con Supabase Auth y permisos reforzados con RLS en Postgres
  (hoy las políticas son permisivas para el rol anónimo)
- Alta y baja de usuarios desde el panel, en vez de editar el arreglo `USUARIOS`
- Numeración correlativa de fichas
- Padrón compartido en Supabase, en vez de local a cada navegador

Las funciones de validación y armado (`autenticar`, `puede`, `normalizarLegajo`,
`resolverLegajo`, `validarAdjunto`, `construirPadron`, `motivosActivos`,
`fechasVigentes`, `filtrarFichas`, `armarCsv`) son puras y no tocan el DOM, así
que pasan tal cual al proyecto Next.js cuando llegue ese momento.
