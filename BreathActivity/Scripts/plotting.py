import os
import json
from dataclasses import dataclass, field
from typing import List, Union
import sys
import matplotlib.pyplot as plt
from scipy.signal import resample

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
 
def largest(arr):
    # Sort the array
    return reduce(max, arr)

def smallest(arr):
    return reduce(min, arr)
        
from scipy.signal import savgol_filter
import numpy as np

width_inches = 1920 / 100  # 38.4 inches
height_inches = 1080 / 100  # 21.6 inches
size = (width_inches, height_inches)
        
def drawPlot(storageData: StorageData):
    fig, axis = plt.subplots(4, len(storageData.data), figsize=size)
        
    axis[0, 0].set_ylabel('respiratory rate (interpolated)')
    axis[1, 0].set_ylabel('pupil size (raw)')
    axis[2, 0].set_ylabel('respiratory rate (trend)')
    axis[3, 0].set_ylabel('pupil size (trend)')
    
    maxPupil = largest(list(map(lambda stage: largest(stage.serialData.pupilSizes), storageData.data)))
    minPupil = smallest(list(map(lambda stage: smallest(stage.serialData.pupilSizes), storageData.data)))
    maxRR = 25
    minRR = 0
    
    for stageIndex, stage in enumerate(storageData.data):
        collumnName = f'{stage.level}, correct: {int(stage.correctRate)}%, feel difficult: {stage.surveyData.q1Answer}, stressful: {stage.surveyData.q2Answer}'
        
        rr_array = stage.serialData.respiratoryRates
        rr_len = len(rr_array)
        rr_indicies = np.linspace(0, rr_len - 1, num=rr_len)
        iterpolated_indices = np.linspace(0, rr_len - 1, num=120)
    
        # interpolated respiratory rate to match with 5 minutes of data
        interpolated_respiratory_rate = np.interp(iterpolated_indices, rr_indicies, rr_array)
        
        # down sample to around one value each 2.5 seconds
        resampledPupil = resample(stage.serialData.pupilSizes, 120)
        
        # smoothing the array to see the trend
        trendingPupil = savgol_filter(resampledPupil, len(resampledPupil), 80)
        meanTrendingPupil = savgol_filter(resampledPupil, len(resampledPupil), 3)
        trendingRR = savgol_filter(interpolated_respiratory_rate, len(interpolated_respiratory_rate), 80)
        meanTrendingRR = savgol_filter(interpolated_respiratory_rate, len(interpolated_respiratory_rate), 3)
        
        time = np.arange(len(interpolated_respiratory_rate))
        markerSize = list(map(lambda x: 1, time))
        mapped_time = list(map(lambda x: x * 5, time))
        
        axis[0, stageIndex].plot(mapped_time, interpolated_respiratory_rate, color='red')
        axis[0, stageIndex].set_ylim(minRR, maxRR)
        axis[0, stageIndex].set_xlabel('linear time')
        axis[0, stageIndex].set_title(collumnName, size='large')
        
        axis[1, stageIndex].plot(mapped_time, resampledPupil, color='green')
        axis[1, stageIndex].set_ylim(minPupil, maxPupil)
        axis[1, stageIndex].set_xlabel('linear time')
        
        axis[2, stageIndex].plot(mapped_time, trendingRR, color='orange')
        axis[2, stageIndex].set_ylim(minRR, maxRR)
        # axis[2, stageIndex].get_yaxis().set_ticks([])
        axis[2, stageIndex].scatter(mapped_time, meanTrendingRR, color='violet',s=markerSize)
        axis[2, stageIndex].set_xlabel('linear time')
        
        axis[3, stageIndex].plot(mapped_time, trendingPupil, color='brown')
        axis[3, stageIndex].scatter(mapped_time, meanTrendingPupil, color='blue',s=markerSize)
        # axis[3, stageIndex].get_yaxis().set_ticks([])
        axis[3, stageIndex].set_ylim(minPupil, maxPupil)
        axis[3, stageIndex].set_xlabel('linear time')
        
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
    for storageData in data:
        try:
            drawPlot(storageData)
        except:
            print('🤷🏻‍♂️ cannot make plot of this')
