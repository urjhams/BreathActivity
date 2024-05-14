import os
import json
from dataclasses import dataclass, field
from typing import List, Union
import sys
import matplotlib.pyplot as plt
from scipy.signal import resample
from scipy.stats import median_abs_deviation
from functools import reduce
import math , pywt , numpy as np
from scipy.signal import savgol_filter
import numpy as np

# parameters
folderPath = sys.argv[1]

# Define Enums
class ReactionType:
    def __init__(self, reactionTime: float):
        self.reactionTime = reactionTime

class ResponseType:
    pass

# Define @dataclass for each struct
@dataclass
class CollectedData:
    pupilSize: float
    respiratoryRate: Union[int, None]

@dataclass
class SerialData:
    pupilSizes: list[float] = field(default_factory=list) 
    respiratoryRates: list[int] = field(default_factory=list) 

@dataclass
class Response:
    type: ResponseType
    reaction: Union[ReactionType, None]

@dataclass
class UserData:
    name: str = ""
    age: str = ""
    gender: str = "Other"
    levelTried: str = ""

@dataclass
class SurveyData:
    q1Answer: Union[int, None]
    q2Answer: Union[int, None]

@dataclass
class ExperimentalData:
    level: str
    response: List[Response]
    collectedData: List[CollectedData]
    serialData: SerialData = SerialData()
    correctRate: Union[float, None] = None
    surveyData: Union[SurveyData, None] = None

@dataclass
class StorageData:
    userData: UserData
    data: List[ExperimentalData]
    comment: str

def readJsonFilesFromFolder(path):
    storageDataList:Union[StorageData, None] = []
    try:
        # Iterate through each file in the folder
        for filename in os.listdir(path):
            filePath = os.path.join(path, filename)
            
            # Check if the file is a JSON file
            if filename.endswith('.json'):
                storageData = readJsonFromFile(filePath)
                storageDataList.append(storageData)

        return storageDataList

    except OSError as e:
        print("Error accessing folder or file:", e)
        return None
    except json.JSONDecodeError as e:
        print("Error decoding JSON data:", e)
        return None

def readJsonFromFile(filePath):
    with open(filePath, 'r') as file:
        # Parse JSON data
        jsonData = json.load(file)
                
        # Extract data from JSON and create instances of ExperimentalData
        experimentalDataList = []
        for experimentalData in jsonData['data']:
            responses = [Response(**response) for response in experimentalData['response']]
            collectedData = [CollectedData(**data) for data in experimentalData['collectedData']]
            experimental_data = ExperimentalData(
                level = experimentalData['level'],
                response = responses,
                collectedData = collectedData,
                serialData = SerialData(**experimentalData.get('serialData', {})),
                correctRate = experimentalData.get('correctRate'),
                surveyData = SurveyData(**experimentalData.get('surveyData', {}))
            )
            experimentalDataList.append(experimental_data)

        # Create UserData instance
        userData = UserData(**jsonData['userData'])
                
        # Create StorageData instance
        return StorageData(
            userData = userData,
            data = experimentalDataList,
            comment = jsonData['comment']
        )

# normalize a list based on upper and lower bounds
def normalized(value, upper, lower, replacement = None):
    if value > upper:
        return upper
    elif value < lower:
        return lower
    else:
        return replacement if replacement else value

#cite: Preprocessing pupil size data: Guidelines and code - Mariska E. Kret, Elio E. Sjak-Shie 
def normalized_outliers_pupil_diameters(raw_pupil_diameter, useMedian = False):
    # Calculate the median absolute deviation from the median
    mad = median_abs_deviation(raw_pupil_diameter)
    
    median = np.median(raw_pupil_diameter)
    
    m_value = 2.5   # moderately conservative

    # Set lower and upper bounds from the median
    # cite: Christophe Leys et al. Detecting outliers: Do not use standard deviation around the mean, use absolute deviation around the median
    upper = median + m_value * mad
    lower = median - m_value * mad

    # Filter data based on bounds
    med = median if useMedian else None
    normalized_pupil_diameter = list(map(lambda x: normalized(x, upper, lower, replacement=med), raw_pupil_diameter))

    return (normalized_pupil_diameter, upper, lower)
 
 # find maximum value in a list
def largest(arr):
    return reduce(max, arr)

# find minimum value in a list
def smallest(arr):
    return reduce(min, arr)

# split a list into chunks of size `chunk_size`
def split_list(lst, chunk_size):
    return list(zip(*[iter(lst)] * chunk_size))

width_inches = 1920 / 100  # 38.4 inches
height_inches = 1080 / 100  # 21.6 inches
size = (width_inches, height_inches)

def standardlized(rr, threshold):
    return rr if rr > threshold else threshold

# Andrew T. Duchowski, Krzysztof Krejtz, Izabela Krejtz, Cezary Biele, Anna Niedzielska, Peter Kiefer, Martin Raubal, and Ioannis Giannopoulos (2018). 
# The Index of Pupillary Activity: Measuring Cognitive Load vis-à-vis Task Difficulty with Pupil Oscillation. 
# In Proceedings of the 2018 CHI Conference on Human Factors in Computing Systems (CHI '18). 
# Association for Computing Machinery, New York, NY, USA, Paper 282, 1–13. https://doi.org/10.1145/3173574.3173856
class PupilData(float):
	def __init__(self, diameter):
		self.X = diameter
		self.timestamp = 0

def modmax(d):
	# compute signal modulus
	m = [0.0] * len(d)
	for i in range(len(d)):
		m[i] = math.fabs(d[i])

	# if value is larger than both neighbours , and strictly
	# larger than either , then it is a local maximum
	t = [0.0]*len(d)
	for i in range(len(d)):
		ll = m[i-1] if i >= 1 else m[i]
		oo = m[i]
		rr = m[i+1] if i < len(d)-2 else m[i]
		if (ll <= oo and oo >= rr) and (ll < oo or oo > rr):
			# compute magnitude
			t[i] = math.sqrt(d[i]**2)
		else:
			t[i] = 0.0
	return t

# requirement: d is a list of float that represent the signal samples every one second.
def ipa(d: list[float]):
	# obtain 2-level DWT of pupil diameter signal d
	try:
		(cA2,cD2,cD1) = pywt.wavedec(d, 'sym16', 'per', level=2)
	except ValueError:
		return

	# get signal duration (IN SECONDS)
	tt = len(d)

	# normalize by 1=2j , j = 2 for 2-level DWT
	cA2[:] = [x / math.sqrt(4.0) for x in cA2]
	cD1[:] = [x / math.sqrt(2.0) for x in cD1]
	cD2[:] = [x / math.sqrt(4.0) for x in cD2]

	# detect modulus maxima
	cD2m = modmax(cD2)

	# threshold using universal threshold lambda_univ = s*sqrt(p(2 log n))
	lambda_univ = np.std(cD2m) * math.sqrt(2.0 * np.log2(len(cD2m)))
	# where s is the standard deviation of the noise
	cD2t = pywt.threshold(cD2m ,lambda_univ, mode='hard')

	# compute IPA
	ctr = 0
	for i in range(len(cD2t)):
		if math.fabs(cD2t[i]) > 0: ctr += 1
  
	IPA = float(ctr)/tt
    
	return IPA
        
def drawPlot(storageData: StorageData):
    print(f'🙆🏻 making plot of data from {storageData.userData.name}')
    fig, axis = plt.subplots(3, len(storageData.data), figsize=size)
        
    axis[0, 0].set_ylabel('pupil diameter (resampled & outliners filtered-in mm)')
    axis[1, 0].set_ylabel('Index of Pupillary Activity (Hz)')
    axis[2, 0].set_ylabel('estimaterd respiratory rate (breaths per minute)')
    
    maxPupil = largest(list(map(lambda stage: largest(stage.serialData.pupilSizes), storageData.data)))
    minPupil = smallest(list(map(lambda stage: smallest(stage.serialData.pupilSizes), storageData.data)))
    maxRR = 25
    minRR = 0
    
    for stageIndex, stage in enumerate(storageData.data):
        rr_array = stage.serialData.respiratoryRates
        rr_len = len(rr_array)
        rr_indicies = np.linspace(0, rr_len - 1, num=rr_len)
        iterpolated_indices = np.linspace(0, rr_len - 1, num=60)
        
        # interpolated respiratory rate to match with 5 minutes of data
        interpolated_respiratory_rate = np.interp(iterpolated_indices, rr_indicies, rr_array)
        
        # resample the pupil size to match with 5 minutes of data (the raw data is around 298 anyway)
        resampled_raw_pupil = resample(stage.serialData.pupilSizes, 300)
        
        # filtered the outlier and replace them with the upper and lower boundary based on Median Absolute Deviation
        (filtered_outlier_pupil, filtered_max , filtered_min) = normalized_outliers_pupil_diameters(resampled_raw_pupil)
        
        # apply savgol filter to smooth the pupil data in a window of 60 samples (which mean 60 seconds)
        normalized_pupil = savgol_filter(filtered_outlier_pupil, 60, 1)
        
        # mean pupil diameter
        mean_pupil = np.mean(filtered_outlier_pupil)
        
        # mapping the pupilData to IPA, `resampled_raw_pupil` contains each element for each second already
        splited = split_list(filtered_outlier_pupil, 5)
        
        # here we calculate the IPA in each section of 5 seconds.
        ipa_values = list(map(lambda data: ipa(data), splited))
        
        # calculate the grand IPA of the whole task
        grand_ipa = ipa(filtered_outlier_pupil)
        
        # smoothing the IPA values
        smoothed_ipa_values = savgol_filter(ipa_values, 12, 1)
        
        # the time blocks for IPA calculation (each 5 seconds)
        ipa_time_blocks = list(map(lambda index: index * 5, range(len(ipa_values))))
        
        time = list(map(lambda index: index * 5, range(len(interpolated_respiratory_rate))))
        
        pupil_raw_time = np.arange(len(resampled_raw_pupil))
        
        # calculate the mean reaction time
        reactionTimes = []
        for response in stage.response:
            if 'pressedSpace' in response.reaction:
                reactionTimes.append(response.reaction['pressedSpace']['reactionTime'])
        mean_reaction_time = np.mean(reactionTimes)
        
        level = stage.level
        correct = int(stage.correctRate)
        q1 = stage.surveyData.q1Answer
        q2 = stage.surveyData.q2Answer
        collumnName = f'{level}, performance: {correct}/100, feel difficult: {q1}, stressful: {q2}'
        collumnName += f'\n reaction: {"{:.2f}".format(mean_reaction_time)}s, mean pupil diameter: {"{:.2f}".format(mean_pupil)}mm'
        
        axis[0, stageIndex].plot(pupil_raw_time, filtered_outlier_pupil, color='brown', label='filtered outlier pupil diameter')
        axis[0, stageIndex].plot(pupil_raw_time, normalized_pupil, color='black', label='normalized')
        axis[0, stageIndex].set_ylim(minPupil, maxPupil)
        axis[0, stageIndex].set_xlabel('time (s)')
        axis[0, stageIndex].set_title(collumnName, size='large')
        
        axis[1, stageIndex].plot(ipa_time_blocks, smoothed_ipa_values, color='orange', label='IPA')
        axis[1, stageIndex].set_ylim(0, 0.2)
        axis[1, stageIndex].set_xlabel('time (every 5s)')
        axis[1, stageIndex].set_title(f'Task IPA: {"{:.3f}".format(grand_ipa)}Hz')
        
        axis[2, stageIndex].plot(time, interpolated_respiratory_rate, color='red', label='Respiratoy rate')
        axis[2, stageIndex].set_ylim(minRR, maxRR)
        axis[2, stageIndex].set_xlabel('time (every 5s)')
        
    userData = storageData.userData
    plt.suptitle(f'{userData.gender} - {userData.age}', fontweight = 'bold', fontsize=18)
    
    # Adjust layout to prevent overlapping of labels
    plt.tight_layout()
    
    plots_dir = f'{folderPath}/plots'
    os.makedirs(plots_dir, exist_ok=True)
    plot = f'{plots_dir}/{storageData.userData.name} ({storageData.userData.levelTried}).png'
    print(f'🙆🏻 saving {plot}')
    
    plt.savefig(plot)
    plt.close()
    
# ------------------ main -----------------

data = readJsonFilesFromFolder(folderPath)

if data:
    # drawPlot(data[1])
    for storageData in data:
        try:
            drawPlot(storageData)
        except:
            print('🤷🏻‍♂️ cannot make plot of this')