# Fichas de excepción — Examen de Ingreso

Aplicación de mesa de entrada para registrar alumnos inscriptos que no podrán
asistir a la fecha de curso asignada, y emitir la ficha de excepción
correspondiente.

La pantalla principal es el listado de fichas emitidas. Las fichas se crean
desde un diálogo que se abre con **Nueva ficha** y se cierra al guardar.

Esta es la **primera etapa**: todo se guarda en el navegador del equipo. La base
de datos compartida llega cuando se active Supabase.

## Acceso

| Usuario | Contraseña | Rol | Qué puede hacer |
|---|---|---|---|
| `ingreso` | `UADE2026` | Operador | Cargar y consultar fichas |
| `Romero` | `lordalan` | Admin | Todo lo anterior + configuración |

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

Abrí `index.html` en el navegador. No requiere instalación, servidor ni build.

### Listado

Cada fila muestra legajo, alumno, motivo, fecha de recuperatorio, la
documentación adjunta y el número de ficha.

- El botón con el nombre del PDF **abre el archivo** en una pestaña nueva.
- **Imprimir** vuelve a emitir esa ficha, con firma y sello, en cualquier momento.
- El buscador filtra por legajo, apellido, motivo o número de ficha.
- **Exportar CSV** baja el listado tal como está filtrado, incluyendo qué usuario
  emitió cada ficha.

### Crear una ficha

1. **Nueva ficha** abre el diálogo.
2. **Legajo** — escribí los 7 dígitos. Se valida contra el padrón en el momento:
   la barra de color y el mensaje debajo indican si el legajo existe, está
   incompleto o no figura. Cuando es válido aparece el nombre del alumno.
3. **Motivo** — seleccionalo de la lista.
4. **Fecha de recuperatorio** — solo aparecen las vigentes.
5. **Documentación** — PDF opcional, hasta 10 MB. Se valida formato y tamaño.
6. **Guardar ficha** — el diálogo se cierra y la ficha aparece en el listado.

El botón Guardar se habilita solo cuando el legajo es válido y están elegidos el
motivo y la fecha. Se puede cancelar con **Cancelar**, la **×** o la tecla Esc.

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
| Sesión abierta | `sessionStorage` | Se cierra con el navegador |
| Padrón de alumnos | `localStorage` | Texto liviano, ~70 KB |
| Listado de fichas | `localStorage` | Texto liviano |
| Motivos y fechas | `localStorage` | Texto liviano |
| PDF adjuntos | `IndexedDB` | Un solo PDF de 10 MB ya excede la cuota de localStorage |

Todo vive en el navegador del equipo. **Lo que se carga en una computadora no se
ve en otra**, y eso vale también para la configuración: si el admin agrega un
motivo en un puesto, hay que repetirlo en los demás. Si se borran los datos del
navegador se pierde el listado. Usá **Exportar CSV** para respaldar.

## Archivos

| Archivo | Qué es |
|---|---|
| `index.html` | La aplicación completa: acceso, listado, carga, configuración y ficha imprimible |
| `padron.js` | Padrón embebido, generado. No editar a mano |
| `build_padron.py` | Regenera `padron.js` desde un Excel |

## Verificación

Abrí `index.html?test` y mirá la consola del navegador. Corre 64 comprobaciones
sobre autenticación y permisos, la configuración de motivos y fechas, la
normalización de legajos y nombres, la resolución contra el padrón, la validación
del adjunto, el parseo y la generación de CSV, el filtrado del listado y el
formato de fechas y números de ficha. Si algo falla, se lanza una excepción con
el caso concreto.

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
`EX-AAAAMMDD-LEGAJO-HHMM`. No es una secuencia global: sin base de datos no hay
forma de garantizar unicidad entre puestos.

## Qué falta para la versión completa

- Autenticación real con Supabase Auth y permisos reforzados con RLS en Postgres
- Base de datos compartida entre equipos, con las fichas y la configuración de todos
- Subir el PDF a Supabase Storage con URLs firmadas, en vez del navegador
- Alta y baja de usuarios desde el panel, en vez de editar el arreglo `USUARIOS`
- Numeración correlativa de fichas

Las funciones de validación y armado (`autenticar`, `puede`, `normalizarLegajo`,
`resolverLegajo`, `validarAdjunto`, `construirPadron`, `motivosActivos`,
`fechasVigentes`, `filtrarFichas`, `armarCsv`) son puras y no tocan el DOM, así
que pasan tal cual al proyecto Next.js cuando llegue ese momento.
