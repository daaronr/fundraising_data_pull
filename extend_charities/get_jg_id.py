# %%
import requests
import csv
from collections import defaultdict
from tqdm import tqdm

class JustGivingPull():
    def __init__(self, api_key: str):
        self.base_url = f"https://api.justgiving.com/{api_key}/v1/onesearch?q="
        self.headers = {"Content-type": "application/json",
                        "Accept": "application/json"}
        
    def get_charity_id(self, charity_registration: str):
        # Default object for missing ID
        missing_results = {"justgiving_id": None,
                           "charity_registration_id": charity_registration,
                           "charity_name": None,
                           "charity_url": None}
        
        r = requests.get(self.base_url + charity_registration, 
                         headers = self.headers)
        
        content = r.json()
        
        if content['Total'] == 0:
            charities = None
        else:
            for response in content['GroupedResults']:
                if response['Title'] == "Charities":
                    charities = response['Results']
                    break
                charities = None
                    
        if charities is None:
            results = missing_results
            return results
        
        for charity in charities:
            if (charity_registration in charity['Subtext']) and charity['CountryCode'] == "United Kingdom":
                results = {"justgiving_id": charity['Id'],
                           "charity_registration_id": charity_registration,
                           "charity_name": charity['Name'],
                           "charity_url": charity['Link']}
            else:
                results = missing_results
            return results

def main():
    api_key = "b83e9729"

    # Read in list of charities
    charity_ids = []
    with open("top_1000_list.csv") as f:
        reader = csv.reader(f, delimiter = ",")
        next(reader)

        for line in reader:
            charity_ids.append(line[0])
    
    justgiving = JustGivingPull(api_key)
    
    print("Collecting JustGiving IDs")
    results = [justgiving.get_charity_id(id) for id in tqdm(charity_ids)]

    out_path = "justgiving_ids.csv"
    
    print(f"Writing results to {out_path}")
    
    with open(out_path, "w") as outfile:
        dict_writer = csv.DictWriter(outfile, results[0].keys())
        dict_writer.writeheader()
        dict_writer.writerows(results)

if __name__ == "__main__":
    main()