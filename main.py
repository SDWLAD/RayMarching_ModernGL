# import moderngl_window as mglw
import pygame as pg
import moderngl as mgl
from pygame.locals import *
import numpy as np

class Camera:
    def __init__(self, position, rotation):
        self.position = position
        self.rotation = rotation


class Engine:
    def __init__(self):
        pg.init()

        self.screen = pg.display.set_mode((1920, 1080), DOUBLEBUF | OPENGL | FULLSCREEN)
        self.ctx = mgl.create_context()

        self.clock = pg.time.Clock()
        self.delta_time = 0
        self.time = 0

        pg.event.set_grab(True)
        pg.mouse.set_visible(False)

        self.is_running = True
        self.on_init()
    
    def on_init(self):
        self.camera = Camera(pg.Vector3(0, 2, -10), pg.Vector3(0, 0, 0))
        self.prog = self.get_program()

        self.prog['resolution'] = (1920, 1080)

        self.vao = self.ctx.simple_vertex_array(self.prog, self.ctx.buffer(np.array([[-1, -1], [1, -1], [-1, 1], [1, 1]], dtype=np.float32)), 'in_vert')

    def get_program(self):
        with open(f'shaders/v.glsl') as file:
            vertex_shader = file.read()

        with open(f'shaders/f.glsl') as file:
            fragment_shader = file.read()

        return self.ctx.program(vertex_shader=vertex_shader, fragment_shader=fragment_shader)

    def handle_events(self):
        for event  in pg.event.get():
            if event.type == QUIT or (event.type == KEYDOWN and event.key == K_ESCAPE):
                self.is_running = False

    def render(self):
        self.ctx.clear(0, 0, 0)
        self.vao.render(mgl.TRIANGLE_STRIP)
        pg.display.flip()

    def update(self):
        self.prog['ro'] = self.camera.position
        self.prog['rot'] = self.camera.rotation

    def run(self):
        while self.is_running:
            self.handle_events()
            self.update()
            self.render()
            self.clock.tick(60)
        quit()

if __name__ == '__main__':
    engine = Engine()
    engine.run()

# class App(mglw.WindowConfig):
#     window_size = 1920, 1080
#     resource_dir = 'shaders'
#     fullscreen = True
#     vsync = True

#     def __init__(self, **kwargs):
#         super().__init__(**kwargs)
#         self.quad = mglw.geometry.quad_fs()
#         self.prog = self.load_program(vertex_shader='v.glsl', fragment_shader='f.glsl')
#         self.set_uniform('resolution', self.window_size)

#         self.camera = Camera((0, 2, -10), (0, 0, 0))

#     def set_uniform(self, u_name, u_value):
#         try:
#             self.prog[u_name] = u_value
#         except KeyError:...
    
#     def render(self, time, frame_time):
#         self.ctx.clear() 

#         self.set_uniform('ro', self.camera.position)
#         self.set_uniform('rot',self.camera.rotation)

#         self.quad.render(self.prog)
    
#     def mouse_drag_event(self, x: int, y: int, dx: int, dy: int):
#         self.camera.rotation = (self.camera.rotation[0] + x/100, self.camera.rotation[1] + y/100, self.camera.rotation[2])

# if __name__ == '__main__':
#     mglw.run_window_config(App)