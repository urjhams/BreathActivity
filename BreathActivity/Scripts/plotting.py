import os
import json
from dataclasses import dataclass, field
from typing import List, Union
import sys
import matplotlib.pyplot as plt
from scipy.signal import resample, find_peaks

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
        
from functools import reduce
import pandas as pd

# Function to process raw average pupil size data and return normalized dilation values
def process_raw_data(average_pupil_sizes):
    # Step 1: Calculate the absolute standard deviation from the median
    mad = np.median(np.abs(average_pupil_sizes - np.median(average_pupil_sizes)))

    # Step 2: Set lower and upper bounds from the median
    up_threshold = np.median(average_pupil_sizes) + 3 * mad
    low_threshold = np.median(average_pupil_sizes) - 3 * mad

    # Step 3: Filter data based on bounds
    filtered_data = average_pupil_sizes[(average_pupil_sizes < up_threshold) & (average_pupil_sizes > low_threshold)]

    # Step 4: Smooth the data
    smoothed_data = pd.Series(filtered_data).rolling(window=3, min_periods=1).mean()

    # Step 5: Calculate a single baseline value
    baseline_value = np.median(smoothed_data.head(10))

    # Subtract baseline value from each data point to get normalized dilation values
    normalized_dilation = smoothed_data - baseline_value

    return list(normalized_dilation)
 
def largest(arr):
    # Sort the array
    return reduce(max, arr)

def smallest(arr):
    return reduce(min, arr)

def split_list(lst, chunk_size):
    return list(zip(*[iter(lst)] * chunk_size))
        
from scipy.signal import savgol_filter
import numpy as np

width_inches = 1920 / 100  # 38.4 inches
height_inches = 1080 / 100  # 21.6 inches
size = (width_inches, height_inches)

def standardlized(rr, threshold):
    if rr > threshold:
        return rr
    else:
        return threshold
        
def drawPlot(storageData: StorageData):
    print(f'🙆🏻 making plot of data from {storageData.userData.name}')
    fig, axis = plt.subplots(3, len(storageData.data), figsize=size)
        
    axis[0, 0].set_ylabel('estimaterd respiratory rate')
    axis[1, 0].set_ylabel('pupil size (raw)')
    axis[2, 0].set_ylabel('normalized dilation values')
    
    maxPupil = largest(list(map(lambda stage: largest(stage.serialData.pupilSizes), storageData.data)))
    minPupil = smallest(list(map(lambda stage: smallest(stage.serialData.pupilSizes), storageData.data)))
    maxRR = 25
    minRR = 0
    
    for stageIndex, stage in enumerate(storageData.data):
        rr_array = list(map(lambda rr: standardlized(rr, 12), stage.serialData.respiratoryRates))
        rr_len = len(rr_array)
        rr_indicies = np.linspace(0, rr_len - 1, num=rr_len)
        iterpolated_indices = np.linspace(0, rr_len - 1, num=300)
        
        # interpolated respiratory rate to match with 5 minutes of data
        interpolated_respiratory_rate = np.interp(iterpolated_indices, rr_indicies, rr_array)
        
        # resample the pupil size to match with 5 minutes of data (the raw data is around 298 anyway)
        resampledPupil = resample(stage.serialData.pupilSizes, 300)
        
        normalized_pupil = resample(process_raw_data(resampledPupil), 300)
                
        time = np.arange(len(interpolated_respiratory_rate))
        
        peakIndexs, property = find_peaks(interpolated_respiratory_rate)
        
        # the peaks with the corresponding pupil size, to see the correlation between when the respiratory rate
        # raised up, does the pupil size decrease or increase (in percentage)
        peaksWithPair = list(map(lambda index: (interpolated_respiratory_rate[index], normalized_pupil[index]), peakIndexs))
        
        # filter peaksWithPair to get the pairs that have negavive pupil value
        negativePupilPairs = list(filter(lambda pair: pair[1] < 0, peaksWithPair))
        negativePupilPairPercentage = int(len(negativePupilPairs)/ len(peaksWithPair) * 100)
        
        level = stage.level
        correct = int(stage.correctRate)
        q1 = stage.surveyData.q1Answer
        q2 = stage.surveyData.q2Answer
        collumnName = f'{level}, correct: {correct}%, feel difficult: {q1}, stressful: {q2}, {negativePupilPairPercentage}%'
        
        axis[0, stageIndex].plot(time, interpolated_respiratory_rate, color='red', label='Respiratoy rate')
        axis[0, stageIndex].set_ylim(minRR, maxRR)
        axis[0, stageIndex].set_xlabel('linear time')
        axis[0, stageIndex].set_title(collumnName, size='large')
        
        axis[1, stageIndex].plot(time, resampledPupil, color='brown', label='average pupil size')
        axis[1, stageIndex].set_ylim(minPupil, maxPupil)
        axis[1, stageIndex].set_xlabel('linear time')
        
        axis[2, stageIndex].plot(time, normalized_pupil, color='orange', label='normalized pupil size')
        axis[2, stageIndex].set_xlabel('linear time')
        
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
    # drawPlot(data[0])
    for storageData in data:
        try:
            drawPlot(storageData)
        except:
            print('🤷🏻‍♂️ cannot make plot of this')
