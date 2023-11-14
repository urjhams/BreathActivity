import time
import os
import tobii_research as tobii

#try to get the eye tracker (at [0])
eyetrackers = tobii.find_all_eyetrackers()

os.system(f'echo {len(eyetrackers)}')

#eyetracker = eyetrackers[0]

a = 0

while True:
  a += 1
  # TODO: we will get eye pupilmetry data in every frame and apply to this `a`
  command = f'echo {a}'
  os.system(command)
  time.sleep(1)
