import time
import os

a = 0

while True:
  a += 1
  command = f'echo {a}'
  os.system(command)
  time.sleep(1)
