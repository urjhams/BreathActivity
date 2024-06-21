import os
import json
from dataclasses import dataclass, field
from typing import List
import sys
import matplotlib.pyplot as plt
from scipy.signal import resample
from scipy.stats import median_abs_deviation
from functools import reduce
import math, pywt, numpy as np
from scipy.signal import savgol_filter
import numpy as np
from enum import Enum
import csv

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
        elif self.level == 'normal':
            return 2
        elif self.level == 'hard':
            return 3
        else:
            return 0
        
    def mean_reaction_time(self):
        # calculate the mean reaction time
        reactionTimes = []
        for response in self.response:
            if 'pressedSpace' in response.reaction and 'correct' in response.type:
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
def normalized_outliers(raw_data, useMedian = False):
    # Calculate the median absolute deviation from the median
    mad = median_abs_deviation(raw_data)
    
    median = np.median(raw_data)
    
    m_value = 2.5   # moderately conservative

    # Set lower and upper bounds from the median
    # cite: Christophe Leys et al. Detecting outliers: Do not use standard deviation around the mean, use absolute deviation around the median
    upper = median + m_value * mad
    lower = median - m_value * mad

    # Filter data based on bounds
    med = median if useMedian else None
    normalized_data = list(
        map(lambda x: normalized(x, upper, lower, replacement=med), raw_data)
    )

    return (normalized_data, upper, lower)
 
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

def compute_ripa(signal_samples: list[float], interval_length=5, window_length=11, polyorder=2, threshold=0.5):
    """
    Calculate the Real-Time Index of Pupillary Activity (RIPA) for every interval_length seconds.
    
    Parameters:
    pupil_diameter (list): List of pupil diameter measurements recorded every second.
    interval_length (int): The length of each interval in seconds (default is 5 seconds).
    window_length (int): The length of the Savitzky-Golay filter window (must be odd, default is 11).
    polyorder (int): The order of the polynomial used to fit the samples (default is 2).
    threshold (float): The threshold for detecting significant oscillations (default is 0.5).
    
    Returns:
    ripa_values (list): The calculated RIPA values for each interval.
    """

    def moving_median(data, window_size):
        """Calculate the moving median with a given window size."""
        return np.array([np.median(data[max(0, i - window_size):i + 1]) for i in range(len(data))])

    def delta_function(value, threshold):
        """Kronecker delta function modified for RIPA calculation."""
        return 1 if value > threshold else 0

    ripa_values = []
    num_intervals = len(signal_samples) // interval_length

    for i in range(num_intervals):
        start_idx = i * interval_length
        end_idx = start_idx + interval_length
        segment = signal_samples[start_idx:end_idx]
        
        if len(segment) < window_length:
            # If segment is smaller than window length, skip the calculation
            continue
        
        # Apply Savitzky-Golay filter to the segment
        smoothed_data = savgol_filter(segment, window_length, polyorder)
        first_derivative = savgol_filter(segment, window_length, polyorder, deriv=1)
        
        # Calculate RIPA for the segment
        median = np.median(smoothed_data)
        count = sum(1 if abs(first_derivative[j]) > median + threshold else 0 for j in range(len(first_derivative)))
        ripa = count / len(first_derivative)
        
        # Normalize and invert RIPA
        ripa_normalized = 1 - ripa
        
        ripa_values.append(ripa_normalized)
    
    return ripa_values

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

def compute_pupil_size_change(raw: list[float]):
    result = [0.0]
    for i in range(1, len(raw)):
        result.append(raw[i] - raw[i - 1])
    return result

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
    (filtered_outlier_pupil, _ , _) = normalized_outliers(resampled_raw_pupil)
            
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

class MeanInformation:
    def __init__(self, type: ExperimentDataType, mean: float, upper: float, lower: float):
        self.type = type
        self.mean = mean
        self.upper = upper
        self.lower = lower
class Mean:
    def __init__(self, type: ExperimentDataType, easy: MeanInformation, normal: MeanInformation, hard: MeanInformation):
        self.type = type
        self.easy = easy
        self.normal = normal
        self.hard = hard
    
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
def grand_mean(type: ExperimentDataType, storageDatas: List[StorageData]):
        easy = MeanInformation(type, 0, 0, 0)
        normal = MeanInformation(type, 0, 0, 0)
        hard = MeanInformation(type, 0, 0, 0)
        for storageData in storageDatas:
            for stage in storageData.data:
                # dertemine the data set based on the type
                if type == ExperimentDataType.PUPIL: dataSet = stage.serialData.pupilSizes
                else: dataSet = stage.serialData.respiratoryRates
                
                mean = np.mean(dataSet)
                upper = np.max(dataSet)
                lower = np.min(dataSet)
                
                # skip the loop if this is an empty data set
                if len(dataSet) == 0: continue
    
                # determine the level of the stage and calculate mean of the data
                if stage.level_as_number() == 1:
                   if easy.mean == 0 and easy.upper == 0 and easy.lower == 0:
                       easy.mean = mean
                       easy.upper = upper
                       easy.lower = lower
                   else:
                       easy.mean = (easy.mean + mean) / 2
                       easy.upper = max(easy.upper, upper)
                       easy.lower = min(easy.lower, lower)
                    
                elif stage.level_as_number() == 2:
                    if normal.mean == 0 and normal.upper == 0 and normal.lower == 0:
                        normal.mean = mean
                        normal.upper = upper
                        normal.lower = lower
                    else:
                        normal.mean = (normal.mean + mean) / 2
                        normal.upper = max(normal.upper, upper)
                        normal.lower = min(normal.lower, lower)
                else:
                    if hard.mean == 0 and hard.upper == 0 and hard.lower == 0:
                        hard.mean = mean
                        hard.upper = upper
                        hard.lower = lower
                    else:
                        hard.mean = (hard.mean + mean) / 2
                        hard.upper = max(hard.upper, upper)
                        hard.lower = min(hard.lower, lower)
        return Mean(type, easy, normal, hard)

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

def analyze_median(storagesData: List[StorageData]):
    print('level, mean pupul diameter (mm), mean respiratory rate (bpm)')
    
    # 2D list to store name and pupil data of each candidate
    pupil_data_all: list[list[str]] = []
    # 2D list to store name and respiratory rate data of each candidate
    rr_data_all: list[list[str]] = []
    
    headers = ['Name', 'Age', 'Gender', 'Easy', 'Normal', 'Hard']
    
    for data in storagesData:
        print(f'🙆🏻 analyzing data from {data.userData.name}')
        
        pupil_data = [data.userData.name, data.userData.age, data.userData.gender, 'x', 'x', 'x']
        rr_data = [data.userData.name, data.userData.age, data.userData.gender, 'x', 'x', 'x']
        for stage in data.data:
            configured_rr = stage.serialData.respiratoryRates
            configured_pupils = stage.serialData.pupilSizes
            # mean pupil diameter
            mean_pupil = np.mean(configured_pupils)
            
            #mean respiratory rate
            mean_rr = np.mean(configured_rr)
            
            f_mean_pupil = "{:.2f}".format(mean_pupil)
            f_mean_rr = "{:.2f}".format(mean_rr)
            pupil_data[stage.level_as_number() + 2] = f_mean_pupil
            rr_data[stage.level_as_number() + 2] = f_mean_rr
            
        rr_data_all.append(rr_data)
        pupil_data_all.append(pupil_data)
        
    # save the data to csv files
    
    with open(f'{folderPath}/individual_mean_respiratory_rate.csv', mode='w', newline='') as rr_file:
        rr_writer = csv.writer(rr_file)
        rr_writer.writerow(headers)
        for row in rr_data_all:
            rr_writer.writerow(np.array(row))
    
    with open(f'{folderPath}/individual_mean_pupil_diameter.csv', mode='w', newline='') as pupil_file:
        pupil_writer = csv.writer(pupil_file)
        pupil_writer.writerow(headers)
        for row in pupil_data_all:
            pupil_writer.writerow(np.array(row))
    
            
def median_box_plot(grand_avg: list[GrandAverage]):
    
    fig, axis = plt.subplots(1, len(grand_avg), figsize=(14, 7))
    
    for index, avg in enumerate(grand_avg):
        if avg.type == ExperimentDataType.PUPIL: title = 'median pupil diameter (mm) for each level'
        else: title = 'median respiratory rate (bpm) for each level'
        # create the box plot for the pupil size
        axis[index].boxplot([np.array(avg.easy), np.array(avg.normal), np.array(avg.hard)])
        axis[index].set_title(title)
        axis[index].set_xticklabels(['easy', 'normal', 'hard'])
        
    plt.suptitle('Grand Average', fontweight = 'bold', fontsize=18)
    
    plots_dir = f'{folderPath}/plots'
    os.makedirs(plots_dir, exist_ok=True)
    plot = f'{plots_dir}/Average_box.png'
    plt.savefig(plot)
    plt.close()
    print(f'🙆🏻 box plot saved at {plot}')
   
# generate plots for each candidate
def generate_plot(storageData: StorageData, grand_avg_pupil: GrandAverage, grand_avg_rr: GrandAverage):
    print(f'🙆🏻 making plot of data from {storageData.userData.name}')
    
    experimentals = storageData.data
    
    # define the maximum and minimum value of the pupil size and respiratory rate in the plot
    maxPupil = largest(list(map(lambda stage: largest(stage.serialData.pupilSizes), experimentals)))
    pupil_up_bound = max(maxPupil, grand_avg_pupil.max()) + 0.1
    minPupil = smallest(list(map(lambda stage: smallest(stage.serialData.pupilSizes), experimentals)))
    pupil_min_bound = min(minPupil, grand_avg_pupil.min()) - 0.1
    maxRR = 25
    minRR = 0
    
    # sort the stages based on the level
    experimentals.sort(key=lambda stage: stage.level_as_number())
    
    # create the plot
    fig, axis = plt.subplots(3, len(experimentals), figsize=size)
    axis[0, 0].set_ylabel('pupil diameter (resampled & outliners filtered-in mm)')
    axis[1, 0].set_ylabel('Change in pupil diameter over time (mm)')
    axis[2, 0].set_ylabel('estimaterd respiratory rate (breaths per minute)')
    
    # iterate through each stage and draw the plot
    for index, stage in enumerate(experimentals):
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
        
        mean_rr = np.mean(configured_rr)
        
        # calculation of changed pupil size over time
        pupil_size_change_over_time = compute_pupil_size_change(configured_pupils)
        normalized_pupil_size_change = savgol_filter(pupil_size_change_over_time, 5, 1)
        
        # # mapping the pupilData to IPA, `resampled_raw_pupil` contains each element for each second already
        # splited = split_list(configured_pupils, 5)
        
        # # here we calculate the IPA in each section of 5 seconds.
        # ipa_values = list(map(lambda data: compute_ipa(data), splited))
        
        # # smoothing the IPA values
        # smoothed_ipa_values = savgol_filter(ipa_values, 5, 1)
        
        # # the time blocks for IPA calculation (each 5 seconds)
        # ipa_time_blocks = list(map(lambda index: index * 5, range(len(ipa_values))))
        
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
        f_mean_rr = "{:.2f}".format(mean_rr)
        f_accuracy = "{:.1f}".format(accuracy)
        
        collumnName =  f'level: {level}' #f'level: {level}, errors: {error_number} time, accuracy rate: {f_accuracy}%\n'
        # collumnName += f'feel difficult: {q1}, stressful: {q2}\n'
        # collumnName += f'avg reaction time: {f_reaction_time} s, mean pupil diameter: {f_mean_pupil} mm'
        # collumnName += f'\n, mean respiratory rate: {f_mean_rr} bpm'
        
        axis[0, index].plot(pupil_raw_time, configured_pupils, color='brown', label='pupil diameter')
        axis[0, index].plot(pupil_raw_time, normalized_pupil, color='black', label='normalized')
        axis[0, index].plot(pupil_raw_time, avg_pupil, color='green', label='grand average', linestyle='solid', alpha=0.4)
        axis[0, index].set_ylim(pupil_min_bound, pupil_up_bound)
        # axis[0, stageIndex].set_ylim(2.2, 4.4)
        axis[0, index].set_xlabel('time (s)')
        axis[0, index].set_title(collumnName, size='large')
        axis[0, index].legend()
        
        axis[1, index].plot(pupil_raw_time, pupil_size_change_over_time, color='orange', label='Pupil diameter change over time')
        axis[1, index].plot(pupil_raw_time, normalized_pupil_size_change, color='black', label='normalized value')
        axis[1, index].set_xlabel('time (every 5s)')
        axis[1, index].legend()
        
        axis[2, index].plot(time, configured_rr, color='red', label='Respiratoy rate')
        axis[2, index].plot(time, avg_rr, color='green', label='grand average respiratory rate', linestyle='dashed', alpha=0.7)
        axis[2, index].set_ylim(minRR, maxRR)
        axis[2, index].set_xlabel('time (every 5s)')
        axis[2, index].legend()
        
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
    print(f'🙆🏻 generate grand average plot')
    levels = [
        ('Easy Task', grand_avg_pupil.easy, grand_avg_rr.easy), 
        ('Normal Task', grand_avg_pupil.normal, grand_avg_rr.normal), 
        ('Hard Task', grand_avg_pupil.hard, grand_avg_rr.hard)
    ]
        
    fig, axis = plt.subplots(3, len(levels), figsize=size)
    axis[0, 0].set_ylabel('resampled & outliners filtered pupil diameter (mm)')
    axis[1, 0].set_ylabel('Change in pupil diameter over time (mm)')
    axis[2, 0].set_ylabel('Estimaterd respiratory rate (breaths per minute)')
    
    for index, (level, pupil, rr) in enumerate(levels):
        pupil_time = np.arange(len(pupil))
        
        (filtered_outlier_pupil, filtered_max , filtered_min) = normalized_outliers(pupil)
        
        # apply savgol filter to smooth the pupil data in a window of 60 samples (which mean 60 seconds)
        normalized_pupil = savgol_filter(filtered_outlier_pupil, 60, 1)
        
        rr_time = list(map(lambda index: index * 5, range(len(rr))))
        
        # # mapping the pupilData to IPA, `resampled_raw_pupil` contains each element for each second already
        # splited = split_list(filtered_outlier_pupil, 5)
        
        # # here we calculate the IPA in each section of 5 seconds.
        # ipa_values = list(map(lambda data: compute_ipa(data), splited))
        
        # ipa_time_blocks = list(map(lambda index: index * 5, range(len(ipa_values))))
        
        #  # smoothing the IPA values with the window of 5 samples (5 seconds of data)
        # smoothed_ipa_values = savgol_filter(ipa_values, 5, 1)
        
        pupil_size_change_over_time = compute_pupil_size_change(filtered_outlier_pupil)
        normalized_pupil_size_change_over_time = savgol_filter(pupil_size_change_over_time, 5, 1)
        pupil_size_change_time_blocks = list(map(lambda index: index, range(len(pupil_size_change_over_time))))
                
        axis[0, index].plot(pupil_time, filtered_outlier_pupil, label=f'pupil diameter', color='brown')
        axis[0, index].plot(pupil_time, normalized_pupil, label=f'normalized pupil diameter', color='black')
        axis[0, index].set_xlabel('time (s)')
        axis[0, index].set_ylim(2.5, 3.6)
        axis[0, index].set_title(level, size='large')
        axis[0, index].legend()
        
        axis[1, index].plot(pupil_size_change_time_blocks, pupil_size_change_over_time, label=f'pupil diameter change over time', color='orange')
        axis[1, index].plot(pupil_size_change_time_blocks, normalized_pupil_size_change_over_time, label=f'normalized value', color='black')
        axis[1, index].set_ylim(-0.6, 0.6)
        axis[1, index].set_xlabel('time (s)')
        axis[1, index].legend()
        
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
    
# create box plots for the survey data in average
def survey_box_plot(data: list[StorageData]):
    print(f'🙆🏻 creating box plot for survey data')
    
    fig, axis = plt.subplots(1, 2, figsize=(14, 7))
    
    all_experiment_data = list(map(lambda storageData: storageData.data, data))
    
    merged = [item for sublist in all_experiment_data for item in sublist]
            
    # easy
    easy_data = list(filter(lambda stage: stage.level_as_number() == 1, merged))
    easy_q1 = list(map(lambda stage: stage.surveyData.q1Answer, easy_data))
    easy_q2 = list(map(lambda stage: stage.surveyData.q2Answer, easy_data))
    
    # normal
    normal_data = list(filter(lambda stage: stage.level_as_number() == 2, merged))
    normal_q1 = list(map(lambda stage: stage.surveyData.q1Answer, normal_data))
    normal_q2 = list(map(lambda stage: stage.surveyData.q2Answer, normal_data))
    
    # hard
    hard_data = list(filter(lambda stage: stage.level_as_number() == 3, merged))
    hard_q1 = list(map(lambda stage: stage.surveyData.q1Answer, hard_data))
    hard_q2 = list(map(lambda stage: stage.surveyData.q2Answer, hard_data))
    
    axis[0].boxplot([np.array(easy_q1), np.array(normal_q1), np.array(hard_q1)])
    axis[0].set_title("feel diffcult")
    axis[0].set_xticklabels(['easy', 'normal', 'hard'])
    
    axis[1].boxplot([np.array(easy_q2), np.array(normal_q2), np.array(hard_q2)])
    axis[1].set_title('Feel stressful')
    axis[1].set_xticklabels(['easy', 'normal', 'hard'])
    
    plt.suptitle('Survey Data', fontweight = 'bold', fontsize=18)
    
    # save the plot
    plots_dir = f'{folderPath}/plots'
    os.makedirs(plots_dir, exist_ok=True)
    plot = f'{plots_dir}/Survey_box.png'
    plt.savefig(plot)
    plt.close()
    print(f'🙆🏻 box plot saved at {plot}')
    
# accuracy rate box plot
def accuracy_box_plot(data: list[StorageData]):
    print(f'🙆🏻 creating box plot for accuracy rate')
    
    fig, axis = plt.subplots()
    
    all_experiment_data = list(map(lambda storageData: storageData.data, data))
    
    merged = [item for sublist in all_experiment_data for item in sublist]
        
    # easy
    easy_data = list(filter(lambda stage: stage.level_as_number() == 1, merged))
    easy_accuracy = list(map(lambda stage: stage.correctRate / 100, easy_data))
    
    # normal
    normal_data = list(filter(lambda stage: stage.level_as_number() == 2, merged))
    normal_accuracy = list(map(lambda stage: stage.correctRate / 100, normal_data))
    
    # hard
    hard_data = list(filter(lambda stage: stage.level_as_number() == 3, merged))
    hard_accuracy = list(map(lambda stage: stage.correctRate / 100, hard_data))
    
    axis.boxplot([np.array(easy_accuracy), np.array(normal_accuracy), np.array(hard_accuracy)])
    axis.set_title("accuracy rate")
    axis.set_xticklabels(['easy', 'normal', 'hard'])
    
    plt.suptitle('Accuracy rate', fontweight = 'bold', fontsize=18)
        
    # save the plot
    plots_dir = f'{folderPath}/plots'
    os.makedirs(plots_dir, exist_ok=True)
    plot = f'{plots_dir}/Accuracy_rate_box.png'
    plt.savefig(plot)
    plt.close()
    print(f'🙆🏻 box plot saved at {plot}')

# reaction time box plot
def reaction_time_box_plot(data: list[StorageData]):
    
    print(f'🙆🏻 creating box plot for reaction')
    
    fig, axis = plt.subplots()
    
    all_experiment_data = list(map(lambda storageData: storageData.data, data))
    
    merged = [item for sublist in all_experiment_data for item in sublist]
    
     # easy
    easy_data = list(filter(lambda stage: stage.level_as_number() == 1, merged))
    easy_reaction_time = list(map(lambda stage: stage.mean_reaction_time(), easy_data))
    
    # normal
    normal_data = list(filter(lambda stage: stage.level_as_number() == 2, merged))
    normal_reaction_time = list(map(lambda stage: stage.mean_reaction_time(), normal_data))
    
    # hard
    hard_data = list(filter(lambda stage: stage.level_as_number() == 3, merged))
    hard_reaction_time = list(map(lambda stage: stage.mean_reaction_time(), hard_data))
    
    axis.boxplot([np.array(easy_reaction_time), np.array(normal_reaction_time), np.array(hard_reaction_time)])
    axis.set_title("reaction time (s)")
    axis.set_xticklabels(['easy', 'normal', 'hard'])
    
    plt.suptitle('Reaction time', fontweight = 'bold', fontsize=18)
        
    # save the plot
    plots_dir = f'{folderPath}/plots'
    os.makedirs(plots_dir, exist_ok=True)
    plot = f'{plots_dir}/Reaction_time_box.png'
    plt.savefig(plot)
    plt.close()
    print(f'🙆🏻 box plot saved at {plot}')
     
# ------------------ main -----------------

data = readJsonFilesFromFolder(folderPath)

if data:
    # apply the configuration step on the data
    for storageData in data: configure_storageData(storageData)
    
    # calculate the grand average of the pupil size and respiratory rate
    grand_average_pupil_signal = grand_average_signal(ExperimentDataType.PUPIL, data)
    grand_average_rr_signal = grand_average_signal(ExperimentDataType.RR, data)
    
    # grand_average_rr_signal.easy = normalized_outliers(grand_average_rr_signal.easy)[0]
    # grand_average_rr_signal.normal = normalized_outliers(grand_average_rr_signal.normal)[0]
    # grand_average_rr_signal.hard = normalized_outliers(grand_average_rr_signal.hard)[0]
    
    # analyze the median of the data from each candidate and save into csv file
    # analyze_median(data)
        
    # create the mean table and boxplot
    # median_box_plot([grand_average_pupil_signal, grand_average_rr_signal])
    
    # create the box plot for the survey data
    # survey_box_plot(data)
    
    # create the box plot for the accuracy rate
    # accuracy_box_plot(data)
    
    # create the box plot for the reaction time
    # reaction_time_box_plot(data)
    
    # draw the plots
    for storageData in data: generate_plot(storageData, grand_average_pupil_signal, grand_average_rr_signal)
    
    # draw the grand average plot
    # generate_grand_average_plot(grand_average_pupil_signal, grand_average_rr_signal)