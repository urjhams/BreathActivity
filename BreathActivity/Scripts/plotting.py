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
        
from scipy.signal import savgol_filter
import numpy as np

def drawPlot(storageData: StorageData):
    
    fig, axis = plt.subplots(3, len(storageData.data), constrained_layout = True) 
    
    axis[0, 0].set_ylabel('respiratory rate')
    axis[1, 0].set_ylabel('pupil size')
    axis[2, 0].set_ylabel('smoothed pupil size')
    
    for stageIndex, stage in enumerate(storageData.data):
        collumnName = f'{stage.level}, correct: {int(stage.correctRate)} %, feel difficult: {stage.surveyData.q1Answer}, stressful: {stage.surveyData.q2Answer}'
        stage.collectedData
    
        rr_array = stage.serialData.respiratoryRates
        rr_len = len(rr_array)
        rr_indicies = np.linspace(0, rr_len - 1, num=rr_len)
        iterpolated_indices = np.linspace(0, rr_len - 1, num=300)
    
        # interpolated respiratory rate to match with 5 minutes of data
        interpolated_respiratory_rate = np.interp(iterpolated_indices, rr_indicies, rr_array)
        
        # resampled serial pupil sizes to match with 5 minutes of data
        pupil_sizes = resample(storageData.data[0].serialData.pupilSizes, 300)
        
        time = np.arange(len(interpolated_respiratory_rate))
       
        smoothed_y = savgol_filter(pupil_sizes, len(pupil_sizes), 100)
        
        axis[0, stageIndex].plot(time, interpolated_respiratory_rate)
        axis[0, stageIndex].set_xlabel('linear time (in sec)')
        axis[0, stageIndex].set_title(collumnName, size='large')
        
        axis[1, stageIndex].plot(time, pupil_sizes)
        axis[1, stageIndex].set_xlabel('linear time (in sec)')
        
        axis[2, stageIndex].plot(time, smoothed_y)
        axis[2, stageIndex].set_xlabel('linear time (in sec)')
    
    userData = storageData.userData
    plt.suptitle(f'{userData.name} - {userData.gender} - {userData.age}')
    
    plots_dir = os.pardir.join(folderPath, 'plots')
    os.makedirs(plots_dir, exist_ok=True)
    plotName = os.pardir.join(plots_dir, f'{storageData.userData.name}.png')
    plt.savefig(plotName)
    plt.close()
    # plt.show()

# ------------------ main -----------------

data = readJsonFilesFromFolder(folderPath)

if data:
    for storageData in data:
        drawPlot(storageData)
