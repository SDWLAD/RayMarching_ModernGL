import pygame as pg

class Camera:
    def __init__(self, position):
        self.position = pg.Vector3(position)
        self.rotation = pg.Vector3(0, 0, 0)
        self.mouse_sensitivity = 0.002

    def update(self):
        self.mouse_control()

    def mouse_control(self):
        mouse_dy, mouse_dx = pg.mouse.get_rel()
        self.rotation.x -= mouse_dx * self.mouse_sensitivity
        self.rotation.y += mouse_dy * self.mouse_sensitivity