import sys, re, json, zipfile
from pathlib import Path
# Requires: pip install glfw PyOpenGL
import glfw
from OpenGL import GL as gl

root = Path(__file__).resolve().parents[1] / 'shaders'
mods = Path(sys.argv[1])  # Pass the ATM 10 minecraft/mods directory.
tags = {}
for jar in mods.glob('*.jar'):
    with zipfile.ZipFile(jar) as z:
        for name in z.namelist():
            m = re.fullmatch(r'data/([^/]+)/tags/block/(.+)\.json', name)
            if m:
                data = json.loads(z.read(name))
                key = ':'.join(m.groups())
                if data.get('replace'): tags[key] = []
                tags.setdefault(key, []).extend(data.get('values', []))
def resolve(tag, seen=frozenset()):
    if tag in seen: return set()
    result = set()
    for entry in tags.get(tag, []):
        value = entry['id'] if isinstance(entry, dict) else entry
        result.update(resolve(value[1:], seen | {tag}) if value.startswith('#') else [value])
    return result
leaves = sorted(resolve('minecraft:leaves'))
print('Installed mod leaf IDs in minecraft:leaves:', len(leaves))
print('Leaf namespaces:', ', '.join(sorted({x.split(':')[0] for x in leaves})))
assert len(leaves) > 20

def expand(path, chain=()):
    assert path not in chain, f'Include cycle: {path}'
    text = path.read_text(encoding='utf-8')
    return re.sub(r'^\s*#include "([^"]+)"\s*$', lambda m: expand(root / m[1].lstrip('/'), (*chain,path)), text, flags=re.M)

assert glfw.init()
glfw.window_hint(glfw.VISIBLE, glfw.FALSE)
glfw.window_hint(glfw.CONTEXT_VERSION_MAJOR, 3)
glfw.window_hint(glfw.CONTEXT_VERSION_MINOR, 3)
glfw.window_hint(glfw.OPENGL_PROFILE, glfw.OPENGL_COMPAT_PROFILE)
window = glfw.create_window(32, 32, 'Shader validation', None, None)
assert window
glfw.make_context_current(window)
print('Driver:', gl.glGetString(gl.GL_RENDERER).decode(), gl.glGetString(gl.GL_VERSION).decode())
count = 0
variants = ['LIGHT', 'BALANCED', 'GAME_CLOUDS', 'NO_SHADOWS', 'ALL_OFF']
try:
    for variant in variants:
        for vertex in sorted(root.rglob('*.vsh')):
            fragment = vertex.with_suffix('.fsh')
            assert fragment.exists(), vertex
            shaders = []
            for file, kind in [(vertex, gl.GL_VERTEX_SHADER), (fragment, gl.GL_FRAGMENT_SHADER)]:
                source = expand(file)
                if variant == 'BALANCED':
                    source = source.replace('#define CLOUD_STYLE 1', '#define CLOUD_STYLE 2').replace('//#define WATER_DEPTH', '#define WATER_DEPTH').replace('shadowMapResolution = 384', 'shadowMapResolution = 512').replace('shadowDistance = 24.0', 'shadowDistance = 32.0')
                if variant == 'GAME_CLOUDS': source = source.replace('#define CLOUD_STYLE 1', '#define CLOUD_STYLE 0')
                if variant == 'NO_SHADOWS': source = source.replace('#define CAST_SHADOWS', '//#define CAST_SHADOWS')
                if variant == 'ALL_OFF':
                    options = re.findall(r'^#define (\w+)\s*$', (root/'lib/settings.glsl').read_text(), re.M)
                    for option in options: source = re.sub(r'^#define '+option+r'\s*$', '// disabled '+option, source, flags=re.M)
                    source = source.replace('#define CLOUD_STYLE 1', '#define CLOUD_STYLE 0')
                source = source.replace('#version 330 compatibility', '#version 330 compatibility\n#define MC_RENDER_STAGE_STARS 9\n#define MC_RENDER_STAGE_SUN 5\n#define MC_RENDER_STAGE_MOON 6')
                source = source.replace('#version 330 compatibility', '#version 330 compatibility\n#define MC_RENDER_STAGE_VOID 2\n#define MC_RENDER_STAGE_SUNSET 3')
                shader = gl.glCreateShader(kind)
                gl.glShaderSource(shader, source)
                gl.glCompileShader(shader)
                assert gl.glGetShaderiv(shader, gl.GL_COMPILE_STATUS), (variant, str(file), gl.glGetShaderInfoLog(shader))
                shaders.append(shader)
            program = gl.glCreateProgram()
            for shader in shaders: gl.glAttachShader(program, shader)
            gl.glLinkProgram(program)
            assert gl.glGetProgramiv(program, gl.GL_LINK_STATUS), (variant, str(vertex), gl.glGetProgramInfoLog(program))
            if vertex.stem == 'gbuffers_clouds':
                gl.glUseProgram(program)
                identity = [1.,0.,0.,0.,0.,1.,0.,0.,0.,0.,1.,0.,0.,0.,0.,1.]
                gl.glUniformMatrix4fv(gl.glGetUniformLocation(program, 'gbufferModelViewInverse'), 1, False, identity)
                gl.glUniform1f(gl.glGetUniformLocation(program, 'fogStart'), 10.)
                gl.glUniform1f(gl.glGetUniformLocation(program, 'fogEnd'), 100.)
                gl.glViewport(0, 0, 32, 32)
                gl.glClearColor(0., 0., 0., 0.)
                gl.glClear(gl.GL_COLOR_BUFFER_BIT)
                gl.glColor4f(1., 0., 0., 1.)
                gl.glBegin(gl.GL_TRIANGLES)
                gl.glVertex3f(-1., -1., 0.)
                gl.glVertex3f(3., -1., 0.)
                gl.glVertex3f(-1., 3., 0.)
                gl.glEnd()
                pixel = gl.glReadPixels(16, 16, 1, 1, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE)
                hidden = vertex.parent.name == 'overworld' and variant not in ['GAME_CLOUDS', 'ALL_OFF']
                assert pixel[0] == (0 if hidden else 255), (variant, str(vertex), pixel)
                gl.glUseProgram(0)
            gl.glDeleteProgram(program)
            for shader in shaders: gl.glDeleteShader(shader)
            count += 1
        print(variant, 'compiled and linked')
finally:
    glfw.destroy_window(window)
    glfw.terminate()
print('PASS:', count, 'program configurations; include graph and installed foliage tags verified')
print('Limitation: direct OpenGL compile, not Iris-transformed programs or an in-game visual test.')
