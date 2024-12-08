from shape import Shape
import numpy as np
import json

class Scene:
    def __init__(self, prog):
        self.load_scene("scene.json")

        for i in range(len(self.shapes)):
            prog[f"shapes[{i}].position"] = self.shapes[i]["position"]
            prog[f"shapes[{i}].size"] = self.shapes[i]["size"]
            prog[f"shapes[{i}].color"] = self.shapes[i]["color"]
            prog[f"shapes[{i}].type"] = self.encode_types(self.shapes[i]["type"])
            prog[f"shapes[{i}].combinationType"] = self.encode_types(self.shapes[i]["combinationType"])
        
    def load_scene(self, path):
        with open(path) as f:
            scene:dict = json.load(f)
            self.shapes = list(scene.values())
    
    @staticmethod
    def encode_types(type):
        types = {
            "Sphere":0,
            "Box":1,
            "Torus":2,
            "Plane":3,
            "Union":0,
            "SoftUnion":3
        }
        return types[type]