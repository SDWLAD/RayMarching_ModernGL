import moderngl_window as mglw


class App(mglw.WindowConfig):
    window_size = 1920, 1080
    resource_dir = 'shaders'
    fullscreen = True
    vsync = True

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.quad = mglw.geometry.quad_fs()
        self.prog = self.load_program(vertex_shader='v.glsl', fragment_shader='f.glsl')
        self.set_uniform('resolution', self.window_size)

    def set_uniform(self, u_name, u_value):
        try:
            self.prog[u_name] = u_value
        except KeyError:...
    
    def render(self, time, frame_time):
        self.ctx.clear()
        self.quad.render(self.prog)

if __name__ == '__main__':
    mglw.run_window_config(App)