import pygame as pg
import math
class Camera:
    def __init__(self, position):
        self.position = pg.Vector3(position)
        self.rotation = pg.Vector3(0, 0, 0)
        self.mouse_sensitivity = 0.002
        self.move_speed = 0.1

    def update(self):
        self.mouse_control()
        self.keyboard_control()

    def mouse_control(self):
        mouse_dy, mouse_dx = pg.mouse.get_rel()
        self.rotation.x -= mouse_dx * self.mouse_sensitivity
        self.rotation.y += mouse_dy * self.mouse_sensitivity
        self.rotation.x = max(min(self.rotation.x, math.pi / 2), -math.pi / 2)
        pg.mouse.set_pos((400, 300))  
    
    def keyboard_control(self):
        keys = pg.key.get_pressed()

        forward = pg.Vector3(
            math.sin(self.rotation.y),
            math.sin(self.rotation.x),
            math.cos(self.rotation.y)
        )
        right = pg.Vector3(
            math.cos(self.rotation.y),
            0,
            -math.sin(self.rotation.y),
        )

        up = pg.Vector3(0, 1, 0)

        if keys[pg.K_w]: self.position += forward * self.move_speed
        if keys[pg.K_s]: self.position -= forward * self.move_speed
        if keys[pg.K_a]: self.position -= right * self.move_speed
        if keys[pg.K_d]: self.position += right * self.move_speed
        if keys[pg.K_SPACE ]: self.position += up * self.move_speed
        if keys[pg.K_LSHIFT]: self.position -= up * self.move_speed