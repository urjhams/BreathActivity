import time
import os

a = 0

while True:
  a += 1
  # TODO: we will get eye pupilmetry data in every frame and apply to this `a`
  command = f'echo {a}'
  os.system(command)
  time.sleep(1)
