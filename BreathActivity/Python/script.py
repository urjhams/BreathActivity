import time
import os
import tobii_research as tobii
import math
import atexit

#try to get the eye tracker (at [0])
eyetrackers = tobii.find_all_eyetrackers()

os.system(f'echo " eye tracker connected: {len(eyetrackers)}"')

# this project just get the first eye tracker that it found.
# (actually we just have one eye tracker stick to the mac anyway)
if len(eyetrackers) == 0:
  os.system('echo "Error: There is no eye tracker connected to this Mac"')
  exit()
eyetracker = eyetrackers[0]

# minimum time that the gaze data could be collected
setupTime = 0.5

gazeData = None

def gazeDataCallback(data):
  global gazeData
  gazeData = data

# example gaze data
#{
#  'device_time_stamp': 168070517,
#  'system_time_stamp': 41307891998,
#  'left_gaze_point_on_display_area': (0.410679429769516, 0.24835629761219025),
#  'left_gaze_point_in_user_coordinate_system': (-25.010534286499023, 155.49673461914062, 50.74281311035156),
#  'left_gaze_point_validity': 1,
#  'left_pupil_diameter': 3.6123809814453125,
#  'left_pupil_validity': 1,
#  'left_gaze_origin_in_user_coordinate_system': (-60.24549102783203, -53.34238052368164, 622.0226440429688),
#  'left_gaze_origin_in_trackbox_coordinate_system': (0.6394217014312744, 0.6666402220726013, 0.4544116258621216),
#  'left_gaze_origin_validity': 1,
#  'right_gaze_point_on_display_area': (0.39534109830856323, 0.21361063420772552),
#  'right_gaze_point_in_user_coordinate_system': (-29.64884376525879, 161.90924072265625, 53.07676315307617),
#  'right_gaze_point_validity': 1,
#  'right_pupil_diameter': 3.355438232421875,
#  'right_pupil_validity': 1,
#  'right_gaze_origin_in_user_coordinate_system': (3.38519287109375, -55.37247085571289, 621.5216674804688),
#  'right_gaze_origin_in_trackbox_coordinate_system': (0.49390071630477905, 0.6750221252441406, 0.4479852318763733),
#  'right_gaze_origin_validity': 1
#}

eyetracker.subscribe_to(tobii.EYETRACKER_GAZE_DATA, gazeDataCallback, as_dictionary=True)

time.sleep(setupTime)

def exit_handler():
    eyetracker.unsubscribe_from(tobii.EYETRACKER_GAZE_DATA, gazeDataCallback)

atexit.register(exit_handler)

while True:
  leftDiameter = gazeData.get('left_pupil_diameter')
  if gazeData != None and not math.isnan(leftDiameter):
    command = f'echo {leftDiameter}'
    os.system(command)

