import os
import json
from dataclasses import dataclass
from typing import List, Union

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
    pupilSizes: List[float] = []
    respiratoryRates: List[int] = []

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

def read_json_files_from_folder(folder_path):
    storage_data_list = []
    try:
        # Iterate through each file in the folder
        for filename in os.listdir(folder_path):
            file_path = os.path.join(folder_path, filename)
            
            # Check if the file is a JSON file
            if filename.endswith('.json'):
                with open(file_path, 'r') as file:
                    # Parse JSON data
                    json_data = json.load(file)
                    
                    # Extract data from JSON and create instances of ExperimentalData
                    experimental_data_list = []
                    for experimental_data_json in json_data['data']:
                        responses = [Response(**response) for response in experimental_data_json['response']]
                        collected_data = [CollectedData(**data) for data in experimental_data_json['collectedData']]
                        experimental_data = ExperimentalData(
                            level=experimental_data_json['level'],
                            response=responses,
                            collectedData=collected_data,
                            serialData=SerialData(**experimental_data_json.get('serialData', {})),
                            correctRate=experimental_data_json.get('correctRate'),
                            surveyData=SurveyData(**experimental_data_json.get('surveyData', {}))
                        )
                        experimental_data_list.append(experimental_data)

                    # Create UserData instance
                    user_data = UserData(**json_data['userData'])
                    
                    # Create StorageData instance
                    storage_data = StorageData(
                        userData=user_data,
                        data=experimental_data_list,
                        comment=json_data['comment']
                    )
                    storage_data_list.append(storage_data)

        return storage_data_list

    except OSError as e:
        print("Error accessing folder or file:", e)
        return None
    except json.JSONDecodeError as e:
        print("Error decoding JSON data:", e)
        return None

# Example usage:
folder_path = #"/path/to/your/folder"  # Replace this with the actual folder path
data = read_json_files_from_folder(folder_path)
if data:
    for storage_data in data:
        print(storage_data)
