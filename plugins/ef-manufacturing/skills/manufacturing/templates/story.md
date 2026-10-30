### Objetivo
Migrar el submenú "<Submódulo>" dentro del menú **<Menú>** al **nuevo sistema Manufactura**, replicando las funcionalidades aplicables.

### Alcance
| Sistema Legacy | Módulo actual | Pantalla actual | Comentarios |
| --- | --- | --- | --- |
| <Talleres/Suministros/...> | <Módulo> | [<Pantalla>](<url legacy>) | `<Controller>` · <proxy → OPS / admin-api> |

### Criterios de aceptación (checklist)
- [ ] Todas las funcionalidades del menú están disponibles en el nuevo sistema.
- [ ] Para cada funcionalidad se documentó claramente su origen (Legacy + módulo + pantalla).
- [ ] Permisos a todo el menú y submenú según corresponda al perfil/roles definidos.
- [ ] Verificación DEV realizada.
- [ ] Verificación del usuario responsable realizada.
- [ ] Menú liberado a producción.

### ¿Qué es?
<Qué es la pantalla y para qué la usa el negocio.>

### ¿Qué hace el usuario?
1. <Acción / vista> (filtros, columnas, botones).

### Reglas y permisos actuales
- <Regla legacy tal cual: filtros, exclusiones, validaciones, quién puede entrar.>

### Permisos en el nuevo sistema
`<slug-view>` · `<slug-action>`. (nombres finales).

### Detalle técnico (para la migración)
- **Link:** <url legacy>
- **Repo legacy:** `<repo>` · `<Controller>` (`<acción>` `:<líneas>`)
- **Vistas:** `View/<...>.ctp` · `js/<...>.js`
- **Datos:** `<tablas>`
- **Errores legacy:** <hechos, sin proponer arreglo>

### Para el equipo de TI (definición de la migración)
- [ ] Identificar a qué paquete corresponde este módulo.
- [ ] Desglosar las tareas técnicas por capa dentro de cada sub-issue.
- [ ] Confirmar el contrato con **OPS** (endpoints existentes) o si se reescribe.
- [ ] Definir los **permisos** en el nuevo sistema.

### Desglose (sub-issues)
- <una por pestaña / por URL, como la ve el usuario>

Fuente viva: [página Notion](<url>)
