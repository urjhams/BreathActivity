import os
import json
from dataclasses import dataclass, field
from typing import List
import sys
import matplotlib.pyplot as plt
from scipy.signal import resample
from scipy.stats import median_abs_deviation
from functools import reduce
import math , pywt , numpy as np
from scipy.signal import savgol_filter
import numpy as np
from enum import Enum

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
    respiratoryRate: int | None

@dataclass
class SerialData:
    pupilSizes: list[float] = field(default_factory=list) 
    respiratoryRates: list[int] = field(default_factory=list) 

@dataclass
class Response:
    type: ResponseType
    reaction: ReactionType | None

@dataclass
class UserData:
    name: str = ""
    age: str = ""
    gender: str = "Other"
    levelTried: str = ""

@dataclass
class SurveyData:
    q1Answer: int | None
    q2Answer: int | None

@dataclass
class ExperimentalData:
    level: str
    response: List[Response]
    collectedData: List[CollectedData]
    serialData: SerialData = SerialData()
    correctRate: float | None = None
    surveyData: SurveyData | None = None
    
    def level_as_number(self):
        if self.level == 'easy':
            return 1
        elif self.level == 'hard':
            return 3
        else:
            return 2
        
    def mean_reaction_time(self):
        # calculate the mean reaction time
        reactionTimes = []
        for response in self.response:
            if 'pressedSpace' in response.reaction:
                reactionTimes.append(response.reaction['pressedSpace']['reactionTime'])
        return np.mean(reactionTimes)
    
    # number of error in the task made by the user
    def number_of_error(self):
        # calculate the number of error
        error = 0
        for response in self.response:
            if 'pressedSpace' in response.reaction and 'incorrect' in response.type:
                error += 1
        return error
    
    # accuracy rate from the task (from both directly pressed and indirectly passed)
    def accuracy(self):
        # number of reaction as pressedSpace and have correct response
        total_correct = 0
        for response in self.response:
            if 'correct' in response.type:
                total_correct += 1
        # calculate the accuracy
        return (total_correct / len(self.response)) * 100

@dataclass
class StorageData:
    userData: UserData
    data: List[ExperimentalData]
    comment: str

def readJsonFilesFromFolder(path):
    storageDataList: StorageData | None = []
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
    if value > upper: return upper
    elif value < lower: return lower
    else: return replacement if replacement else value

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
    normalized_pupil_diameter = list(
        map(lambda x: normalized(x, upper, lower, replacement=med), raw_pupil_diameter)
    )

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

def find_modulus_maxima(data):
    # compute signal modulus
    modulus = [0.0] * len(data)
    for i in range(len(data)):
        modulus[i] = math.fabs(data[i])

    # if value is larger than both neighbours , and strictly
    # larger than either, then it is a local maximum
    local_maxima = [0.0]*len(data)
    for i in range(len(data)):
        left_neighbour = modulus[i-1] if i >= 1 else modulus[i]
        current_value = modulus[i]
        right_neighbour = modulus[i+1] if i < len(data)-2 else modulus[i]
        if (left_neighbour <= current_value and current_value >= right_neighbour) and (left_neighbour < current_value or current_value > right_neighbour):
            # compute magnitude
            local_maxima[i] = math.sqrt(data[i]**2)
        else:
            local_maxima[i] = 0.0
    return local_maxima

# requirement: signal_samples is a list of float that represent the signal samples every one second.
def compute_ipa(signal_samples: list[float]):
    # obtain 2-level DWT of pupil diameter signal
    try:
        (approx_coeff_2, detail_coeff_2, detail_coeff_1) = pywt.wavedec(signal_samples, 'sym16', 'per', level=2)
    except ValueError:
        return

    # get signal duration (IN SECONDS)
    signal_duration = len(signal_samples)

    # normalize by 1=2j , j = 2 for 2-level DWT
    approx_coeff_2[:] = [x / math.sqrt(4.0) for x in approx_coeff_2]
    detail_coeff_1[:] = [x / math.sqrt(2.0) for x in detail_coeff_1]
    detail_coeff_2[:] = [x / math.sqrt(4.0) for x in detail_coeff_2]

    # detect modulus maxima
    modulus_maxima = find_modulus_maxima(detail_coeff_2)

    # threshold using universal threshold lambda_univ = s*sqrt(p(2 log n))
    universal_threshold = np.std(modulus_maxima) * math.sqrt(2.0 * np.log2(len(modulus_maxima)))
    # where s is the standard deviation of the noise
    thresholded_data = pywt.threshold(modulus_maxima, universal_threshold, mode='hard')

    # compute IPA
    count = 0
    for i in range(len(thresholded_data)):
        if math.fabs(thresholded_data[i]) > 0: count += 1
  
    ipa = float(count)/signal_duration
    
    return ipa

def compute_lhipa(pupil_diameter_data: list[float]):
    # find max decomposition level
    wavelet = pywt.Wavelet('sym16')
    max_level = pywt.dwt_max_level(len(pupil_diameter_data), wavelet.dec_len)
    
    # set high and low frequency band indices
    high_freq, low_freq = 1, int(max_level/2)
    
    # get detail coefficients of pupil diameter signal
    high_freq_coeff = pywt.downcoef('d', pupil_diameter_data, 'sym16', 'per', level=high_freq)
    low_freq_coeff = pywt.downcoef('d', pupil_diameter_data, 'sym16', 'per', level=low_freq)
    
    # normalize by 1/sqrt(2^j)
    high_freq_coeff[:] = [x / math.sqrt(2**high_freq) for x in high_freq_coeff]
    low_freq_coeff[:] = [x / math.sqrt(2**low_freq) for x in low_freq_coeff]
    
    # obtain the LH:HF ratio
    lh_hf_ratio = low_freq_coeff
    for index in range(len(lh_hf_ratio)):
        lh_hf_ratio[index] = low_freq_coeff[index] / high_freq_coeff[((2**low_freq)/(2**high_freq))/index]
        
    # detect modulus maxima
    modulus_maxima = find_modulus_maxima(lh_hf_ratio)
    
    # threshold using universal threshold lambda_univ = omega*sqrt(p(2 log n))
    # where omega is the standard deviation of the noise
    universal_threshold = np.std(modulus_maxima) * math.sqrt(2.0 * np.log2(len(modulus_maxima)))
    thresholded_data = pywt.threshold(modulus_maxima, universal_threshold, mode='less')
    
    # get signal duration (in seconds)
    signal_duration = len(pupil_diameter_data)
    
    # compute LHIPA
    count = 0
    for i in range(len(thresholded_data)):
        if math.fabs(thresholded_data[i]) > 0: count += 1
    lhipa = float(count)/signal_duration
    
    return lhipa

def configured(stage: ExperimentalData):
    original_rr = stage.serialData.respiratoryRates
    original_pupils = stage.serialData.pupilSizes
        
    ### apply the interpolated in whole the experimentals's respiratory rate and replace to its serialData.respiratoryRates
    rr_len = len(original_rr)
    rr_indicies = np.linspace(0, rr_len - 1, num=rr_len)
    iterpolated_indices = np.linspace(0, rr_len - 1, num=60)
        
    # interpolated respiratory rate to match with 5 minutes of data and apply it back to the original respiratory rate data
    stage.serialData.respiratoryRates = np.interp(iterpolated_indices, rr_indicies, original_rr)
        
    ### apply the resampled and remove the outlier in whole the experimentals's pupilSizes and replace to its serialData.pupilSizes
        
    # resample the pupil size to match with 5 minutes of data (the raw data is around 298 anyway)
    resampled_raw_pupil = resample(original_pupils, 300)
        
    # filtered the outlier and replace them with the upper and lower boundary based on Median Absolute Deviation
    (filtered_outlier_pupil, filtered_max , filtered_min) = normalized_outliers_pupil_diameters(resampled_raw_pupil)
        
    # apply the filtered to original pupil data
    stage.serialData.pupilSizes = filtered_outlier_pupil
    
    return stage

def configure_storageData(storageData: StorageData):
    experimentals = storageData.data
    
    # configure the respiratory rate and pupil size data
    for stage in experimentals:
        stage = configured(stage)
        
    # filter the list to remove the corrupted data (which has the same value in whole the pupil size data)
    experimentals = list(
        filter(
            lambda stage: not all_same(stage.serialData.pupilSizes) 
            and not all_same(stage.serialData.respiratoryRates), 
            experimentals
        )
    )
    
    storageData.data = experimentals

def all_same(lst):
    return all(x == lst[0] for x in lst)

class ExperimentDataType(Enum):
    PUPIL = 1
    RR = 2
    
# grand average class that contains: type (ExperimentDataType), easy, normal, hard data as array
class GrandAverage:
    def __init__(self, type: ExperimentDataType, easy: list, normal: list, hard: list):
        self.type = type
        self.easy = easy
        self.normal = normal
        self.hard = hard
        
    def combined(self):
        result = []
        for element in self.easy: result.append(element)
        for element in self.normal: result.append(element)
        for element in self.hard: result.append(element)
        return result
        
    def min(self):
        return smallest(self.combined())
    
    def max(self):
        return largest(self.combined())
    
    def average(self):
        return np.average([self.easy, self.normal, self.hard], axis=0)
    
# grand average of the data in the list of storageData to combine the data
def grand_average(type: ExperimentDataType, storageDatas: List[StorageData]):
        
        easy_data = []
        normal_data = []
        hard_data = []
        
        for storageData in storageDatas:
            for stage in storageData.data:
                # dertemine the data set based on the type
                if type == ExperimentDataType.PUPIL: dataSet = stage.serialData.pupilSizes
                else: dataSet = stage.serialData.respiratoryRates
                
                mean = np.mean(dataSet)
                
                # skip the loop if this is an empty data set
                if len(dataSet) == 0: continue
    
                # determine the level of the stage and calculate mean of the data
                if stage.level_as_number() == 1:
                    if len(easy_data) == 0: easy_data = [mean] * len(dataSet)
                    else: easy_data = [(easy_data[0] + mean) / 2] * len(dataSet)
                elif stage.level_as_number() == 2:
                    if len(normal_data) == 0: normal_data = [mean] * len(dataSet)
                    else: normal_data = [(normal_data[0] + mean) / 2] * len(dataSet)
                else:
                    if len(hard_data) == 0: hard_data = [mean] * len(dataSet)
                    else: hard_data = [(hard_data[0] + mean) / 2] * len(dataSet)
                    
        return GrandAverage(type, easy_data, normal_data, hard_data)

# grand average of the data in the list of storageData to combine the data (as signal)
# in the same level across the whole candidates
def grand_average_signal(type: ExperimentDataType, storageDatas: List[StorageData]):
    
    easy_data = []
    normal_data = []
    hard_data = []
    
    for storageData in storageDatas:
        for stage in storageData.data:
            # dertemine the data set based on the type
            if type == ExperimentDataType.PUPIL: dataSet = stage.serialData.pupilSizes
            else: dataSet = stage.serialData.respiratoryRates
            
            # skip the loop if this is an empty data set
            if len(dataSet) == 0: continue

            # determine the level of the stage and calculate average the data
            # Calculate the average of each loop to get the grand average of the whole list
            if stage.level_as_number() == 1:
                if len(easy_data) == 0: easy_data = dataSet
                else: easy_data = np.average([easy_data, dataSet], axis=0)
            elif stage.level_as_number() == 2:
                if len(normal_data) == 0: normal_data = normal_data = dataSet
                else: np.average([normal_data, dataSet], axis=0)
            else:
                if len(hard_data) == 0: hard_data = dataSet
                else: hard_data = np.average([hard_data, dataSet], axis=0)
                
    return GrandAverage(type, easy_data, normal_data, hard_data)

# generate plots for each candidate
def generate_plot(storageData: StorageData, grand_avg_pupil: GrandAverage, grand_avg_rr: GrandAverage):
    print(f'🙆🏻 making plot of data from {storageData.userData.name}')
    
    experimentals = storageData.data
    
    # define the maximum and minimum value of the pupil size and respiratory rate in the plot
    maxPupil = largest(list(map(lambda stage: largest(stage.serialData.pupilSizes), experimentals)))
    pupil_up_bound = max(maxPupil, grand_average_pupil.max()) + 0.1
    minPupil = smallest(list(map(lambda stage: smallest(stage.serialData.pupilSizes), experimentals)))
    pupil_min_bound = min(minPupil, grand_average_pupil.min()) - 0.1
    maxRR = 25
    minRR = 0
    
    # sort the stages based on the level
    experimentals.sort(key=lambda stage: stage.level_as_number())
    
    # create the plot
    fig, axis = plt.subplots(3, len(experimentals), figsize=size)
    axis[0, 0].set_ylabel('pupil diameter (resampled & outliners filtered-in mm)')
    axis[1, 0].set_ylabel('Index of Pupillary Activity (Hz)')
    axis[2, 0].set_ylabel('estimaterd respiratory rate (breaths per minute)')
    
    # iterate through each stage and draw the plot
    for stageIndex, stage in enumerate(experimentals):
        configured_rr = stage.serialData.respiratoryRates
        configured_pupils = stage.serialData.pupilSizes
        
        if stage.level_as_number() == 1:
            avg_pupil = grand_avg_pupil.easy
            avg_rr = grand_avg_rr.easy
        elif stage.level_as_number() == 2:
            avg_pupil = grand_avg_pupil.normal
            avg_rr = grand_avg_rr.normal
        else:
            avg_pupil = grand_avg_pupil.hard
            avg_rr = grand_avg_rr.hard
        
        # apply savgol filter to smooth the pupil data in a window of 60 samples (which mean 60 seconds)
        normalized_pupil = savgol_filter(configured_pupils, 60, 1)
        
        # mean pupil diameter
        mean_pupil = np.mean(configured_pupils)
        
        # mapping the pupilData to IPA, `resampled_raw_pupil` contains each element for each second already
        splited = split_list(configured_pupils, 5)
        
        # here we calculate the IPA in each section of 5 seconds.
        ipa_values = list(map(lambda data: compute_ipa(data), splited))
        
        # calculate the grand IPA of the whole task
        grand_ipa = compute_ipa(configured_pupils)
        
        # smoothing the IPA values
        smoothed_ipa_values = savgol_filter(ipa_values, 5, 1)
        
        # the time blocks for IPA calculation (each 5 seconds)
        ipa_time_blocks = list(map(lambda index: index * 5, range(len(ipa_values))))
        
        time = list(map(lambda index: index * 5, range(len(configured_rr))))
        
        pupil_raw_time = np.arange(len(configured_pupils))
        
        # information of the stage
        level = stage.level
        q1 = stage.surveyData.q1Answer
        q2 = stage.surveyData.q2Answer
        mean_reaction_time = stage.mean_reaction_time()
        error_number = stage.number_of_error()
        accuracy = stage.accuracy()
        
        # format of the information
        f_reaction_time = "{:.2f}".format(mean_reaction_time)
        f_mean_pupil = "{:.2f}".format(mean_pupil)
        f_accuracy = "{:.1f}".format(accuracy)
        
        collumnName = f'level: {level}, errors: {error_number} time, accuracy rate: {f_accuracy}%\n'
        collumnName += f'feel difficult: {q1}, stressful: {q2}\n'
        collumnName += f'avg reaction time: {f_reaction_time} s, mean pupil diameter: {f_mean_pupil} mm'
        
        axis[0, stageIndex].plot(pupil_raw_time, configured_pupils, color='brown', label='filtered outlier pupil diameter')
        axis[0, stageIndex].plot(pupil_raw_time, normalized_pupil, color='black', label='normalized')
        axis[0, stageIndex].plot(pupil_raw_time, avg_pupil, color='green', label='grand average pupil diameter', linestyle='solid', alpha=0.4)
        axis[0, stageIndex].set_ylim(pupil_min_bound, pupil_up_bound)
        # axis[0, stageIndex].set_ylim(2.2, 4.4)
        axis[0, stageIndex].set_xlabel('time (s)')
        axis[0, stageIndex].set_title(collumnName, size='large')
        
        axis[1, stageIndex].plot(ipa_time_blocks, smoothed_ipa_values, color='orange', label='IPA')
        axis[1, stageIndex].set_ylim(0, 0.2)
        axis[1, stageIndex].set_xlabel('time (every 5s)')
        axis[1, stageIndex].set_title(f'Task IPA: {"{:.3f}".format(grand_ipa)}Hz')
        
        axis[2, stageIndex].plot(time, configured_rr, color='red', label='Respiratoy rate')
        axis[2, stageIndex].plot(time, avg_rr, color='green', label='grand average respiratory rate', linestyle='dashed', alpha=0.7)
        axis[2, stageIndex].set_ylim(minRR, maxRR)
        axis[2, stageIndex].set_xlabel('time (every 5s)')
        
    userData = storageData.userData
    plt.suptitle(f'{userData.gender} - {userData.age}', fontweight = 'bold', fontsize=18)
    
    # Adjust layout to prevent overlapping of labels
    plt.tight_layout()
    
    # save the plot
    plots_dir = f'{folderPath}/plots'
    os.makedirs(plots_dir, exist_ok=True)
    plot = f'{plots_dir}/{storageData.userData.name} ({storageData.userData.levelTried}).png'
    
    plt.savefig(plot)
    plt.close()
    print(f'🙆🏻 plot saved at {plot}')
    
def generate_grand_average_plot(grand_avg_pupil: GrandAverage, grand_avg_rr: GrandAverage):
    print()
    levels = [
        ('easy', grand_avg_pupil.easy, grand_avg_rr.easy), 
        ('normal', grand_avg_pupil.normal, grand_avg_rr.normal), 
        ('hard', grand_avg_pupil.hard, grand_avg_rr.hard)
    ]
        
    fig, axis = plt.subplots(3, len(levels), figsize=size)
    axis[0, 0].set_ylabel('pupil diameter (resampled & outliners filtered-in mm)')
    axis[1, 0].set_ylabel('Index of Pupillary Activity (Hz)')
    axis[2, 0].set_ylabel('estimaterd respiratory rate (breaths per minute)')
    
    for index, (level, pupil, rr) in enumerate(levels):
        print(f'🙆🏻 generate grand average plot')
        pupil_time = np.arange(len(pupil))
        
        # apply savgol filter to smooth the pupil data in a window of 60 samples (which mean 60 seconds)
        normalized_pupil = savgol_filter(pupil, 60, 1)
        
        rr_time = list(map(lambda index: index * 5, range(len(rr))))
        
         # mapping the pupilData to IPA, `resampled_raw_pupil` contains each element for each second already
        splited = split_list(pupil, 5)
        
        # here we calculate the IPA in each section of 5 seconds.
        ipa_values = list(map(lambda data: compute_ipa(data), splited))
        
        ipa_time_blocks = list(map(lambda index: index * 5, range(len(ipa_values))))
        
         # smoothing the IPA values with the window of 5 samples (5 seconds of data)
        smoothed_ipa_values = savgol_filter(ipa_values, 5, 1)
        
        axis[0, index].plot(pupil_time, pupil, label=f'pupil diameter', color='blue')
        axis[0, index].plot(pupil_time, normalized_pupil, label=f'normalized pupil diameter', color='black')
        axis[0, index].set_xlabel('time (in second)')
        axis[0, index].set_title(level, size='large')
        
        axis[1, index].plot(ipa_time_blocks, smoothed_ipa_values, label=f'pupil diameter', color='blue')
        axis[1, index].set_xlabel('time (every 5s)')
        
        axis[2, index].plot(rr_time, rr, label=f'respiratory rate', color='red')
        axis[2, index].set_ylim(0, 25)
        axis[2, index].set_xlabel('time (every 5s)')
        
    plt.suptitle('Grand Average', fontweight = 'bold', fontsize=18)
    
    # Adjust layout to prevent overlapping of labels    
    plt.tight_layout()
     # save the plot
    plots_dir = f'{folderPath}/plots'
    os.makedirs(plots_dir, exist_ok=True)
    plot = f'{plots_dir}/Average.png'
    plt.savefig(plot)
    plt.close()
    print(f'🙆🏻 plot saved at {plot}')
     
# ------------------ main -----------------

data = readJsonFilesFromFolder(folderPath)

if data:
    # apply the configuration step on the data
    for storageData in data: configure_storageData(storageData)
    
    # calculate the grand average of the pupil size and respiratory rate
    grand_average_pupil = grand_average_signal(ExperimentDataType.PUPIL, data)
    grand_average_rr = grand_average_signal(ExperimentDataType.RR, data)
    
    # TODO: draw the grand average signal in a seperate plot (with calculated grand average IPA)
    # TODO: in the grand average signal, maybe : for each index in the same level array, 
    # find the array of all candidate's at that index and remove outliers then calculate 
    # the mean of the array as the value of that index    
    
    generate_grand_average_plot(grand_average_pupil, grand_average_rr)
    
    # draw the plots
    for storageData in data: generate_plot(storageData, grand_average_pupil, grand_average_rr)