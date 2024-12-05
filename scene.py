from shape import Shape
import numpy as np

class Scene:
    def __init__(self, prog):
        self.shapes = [
            Shape((0, 3, 0), (1.3,1.3,1.3), (1, 0, 0), 0, 0),
            Shape((0, 1, 0), (1, 1, 1), (0, 0, 1), 1, 3),
            Shape((0, 5, 0), (4, 0.6, 0), (0, 1, 0), 2, 0),
            Shape((0, 0, 0), (0, 0, 0), (1, 1, 1), 3, 0),
        ]
        
        for i in range(len(self.shapes)):
            prog[f"shapes[{i}].position"] = self.shapes[i].position
            prog[f"shapes[{i}].size"] = self.shapes[i].size
            prog[f"shapes[{i}].color"] = self.shapes[i].color
            prog[f"shapes[{i}].type"] = self.shapes[i].type
            prog[f"shapes[{i}].combinationType"] = self.shapes[i].combinationType