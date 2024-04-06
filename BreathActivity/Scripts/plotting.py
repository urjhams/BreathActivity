import os
import json
from dataclasses import dataclass, field
from typing import List, Union
import sys
import matplotlib.pyplot as plt

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
        
folderPath = sys.argv[1]
data = readJsonFilesFromFolder(folderPath)

from scipy.signal import savgol_filter

def drawPlot(storageData: StorageData):
    index = 0
    x = []
    yPupilSize = []
    yRespiratoryRate = []
    
    plt.title = storageData.userData.name
    
    for stage in storageData.data:
        collumnName = stage.level
        stage.collectedData
    
    for element in storageData.data[0].collectedData:
       yPupilSize.append(element.pupilSize)
       yRespiratoryRate.append(element.respiratoryRate)
       index += 1
       x.append(index) 
       
    smoothed_y = savgol_filter(yPupilSize, len(yPupilSize), 3)
    
    #TODO: draw :
    # UserName
    # Task_level(correction rate)   Task_level(correction rate)   Task_level(correction rate)
    # Respiratory plot              Respiratory plot              Respiratory plot
    # Pupil dialect + smooth plot   Pupil dialect + smooth plot   Pupil dialect + smooth plot
    
    figure, axis = plt.subplots(3, 1, constrained_layout = True) 
    
    axis[0].plot(x, yRespiratoryRate)
    axis[0].set_title("respiratory rate")
    
    axis[1].plot(x, yPupilSize)
    axis[1].set_title("Pupil size")
    
    axis[2].plot(x, smoothed_y)
    axis[2].set_title("smoothed pupil size")
    
    #TODO: save the plot as a png
    plt.show()

if data:
    for storageData in data:
        drawPlot(storageData)
