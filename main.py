from camera import Camera
import pygame as pg
import moderngl as mgl
from pygame.locals import *
import numpy as np

from scene import Scene

class Engine:
    screen_size = (1920, 1080)

    def __init__(self):
        pg.init()

        self.screen = pg.display.set_mode(self.screen_size, DOUBLEBUF | OPENGL | FULLSCREEN, vsync=1)
        self.ctx = mgl.create_context()

        self.clock = pg.time.Clock()
        self.delta_time = 0
        self.time = 0

        pg.mouse.set_visible(False)

        self.is_running = True
        self.on_init()

    def on_init(self):
        self.camera = Camera(pg.Vector3(0, 2, -10))
        self.prog = self.get_program()

        self.prog['resolution'] = self.screen_size

        self.scene = Scene(self.prog) 

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

        self.camera.update()

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