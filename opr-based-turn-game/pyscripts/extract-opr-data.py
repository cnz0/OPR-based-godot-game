import requests
import os
import json


def fetch_army_names_data(url: str) -> list[str]:

    army_names = []

    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()

        # Extract the 'name' field from each dictionary in the list
        army_names = [army['name'] for army in data]
    else:
        print("Failed to fetch data:", response.status_code)

    return army_names


def save_unit_names_to_file(names: list[str], info: dict[any, list]):
    folder_path = os.path.join(os.getcwd(), 'opr-based-turn-game', 'config')
    file_path = os.path.join(folder_path, 'army_files.txt')

    # Ensure the folder exists
    os.makedirs(folder_path, exist_ok=True)

    # Check if the file already exists and compare contents
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as file:
            current_data = file.read().splitlines()
        if current_data == names:
            print("No changes detected, file not updated.")
            return

    # Write the new data to the file
    with open(file_path, 'w', encoding='utf-8') as file:
        for name in names:
            file.write(name + '\n')

    print(f"Data saved successfully to {file_path}")


def save_to_file(file_name, header, units_content, upgrades_content):
    # Prepare content
    new_content = header + "\n".join(units_content)
    if upgrades_content:
        upgrades_text = "\n\nUpgrades:\n" + json.dumps(upgrades_content, indent=2)
        new_content += upgrades_text

    # Check if the file exists and compare contents
    if os.path.exists(file_name):
        with open(file_name, "r") as file:
            existing_content = file.read()

        if existing_content == new_content:
            print(f"No changes detected for {file_name}, skipping file write.")
            return

    # Save to file
    with open(file_name, "w") as file:
        file.write(new_content)
        print(f"File saved: {file_name}")


def fetch_army_data():
    armies_urls = ["w7qor7b2kuifcyvk", "78qp9l5alslt6yj8", "xnnqhh1775kvmz2r", "xp5zwh73lg1uaym4", "w70ha3o85pa7nigq", "rvvb3kdn2x2pqkki", "yxjboa8oma9bbdck",
                   "7oi8zeiqfamiur21", "ewbra8nv3nq3k27p", "z8205ez2boggzs22", "q11la9v8h1heu9ja", "fk1mkbp8apvltu0z", "nyh41t82jugcdq8m", "vux1Y5vvULmaxZ8P",
                   "bF00yJmGNJ7VxfkN", "NiptqIlNnPHx7x-X", "mI0ZlbFpoT0VqC3M", "_5ObRZWuPMwProbC", "qLonG2G2KzkRQoGf", "cV1jqgtZj8sf57ld", "8P8zHTe_MQtawcCN",
                   "ukrBO4ITaKUpUFeO", "o4D-c-28lvmybgc5", "G5uvPlnfxPg3EcYG", "tH3gqRwsigE87z5H", "7o6om21wxlvvy3hq", "r6hr29338u4micfw", "drqw1iswxmuugp3d",
                   "jlray7cwf8mvw5sn", "31xjrm9ivdimkjxp", "7i7blhft75q9zfdc", "z65fgu0l29i4lnlu", "jpc0kyil0juwy602", "dnthspt7c0klhmt8", "BKi_hJaJflN8ZorH",
                   "7el7k3hgy5pb9o9i", "1wj1ysgxpuuz9bc7", "oqnnu0gk8q6hyyny", "7ex2x15bpkmy1alv", "gk7me4sgn9s740kw", "wopr4xvwa51xh3mc", "rl7ympklz4r0ls38",
                   "e8mflytiz51kc4n6", "hk70l4d471plza00", "5wbcv465hacdwvkb", "4k5amkxoybdiqotm", "U6hwlur14RpnInZr", "zz3kp5ry7ks6mxcx", "04z57ua0bwth37zh",
                   "9qvy1oufoangt2gl", "fmuqw5lr5l6dq0mq", "prsajf5ot936qznk"]

    save_directory = os.path.join(os.getcwd(), 'opr-based-turn-game', 'config')
    os.makedirs(save_directory, exist_ok=True)

    for url in armies_urls:
        specific_army_url = f"https://army-forge.onepagerules.com/api/army-books/{url}?gameSystem=3"
        response = requests.get(specific_army_url)

        if response.status_code == 200:
            data = response.json()
            army_name = data.get("name", "Unnamed Army")

            # Extract units and upgrade packages
            units = data.get('units', [])
            upgrade_packages = data.get('upgradePackages', [])

            # Convert units and upgrades to strings
            units_as_strings = [json.dumps(unit) for unit in units]
            extracted_upgrades = []
            for package in upgrade_packages:
                for section in package.get('sections', []):
                    for option in section.get('options', []):
                        costs = option.get('costs', [])
                        gains = option.get('gains', [])
                        # Combine costs and gains into pairs
                        upgrade_data = [{'costs': cost, 'gains': gain} for cost, gain in zip(costs, gains)]
                        extracted_upgrades.extend(upgrade_data)
            #print(f"Extracted upgrades for {army_name}:")
            #print(json.dumps(extracted_upgrades, indent=2))

            # Set the full file paths with directory
            units_file_name = os.path.join(save_directory, f"{army_name}.txt")

            # Save units to file
            save_to_file(units_file_name, "Units:\n", units_as_strings, extracted_upgrades)

        else:
            print("Failed to fetch data:", response.status_code)

#army_names = fetch_army_names_data("https://army-forge.onepagerules.com/api/army-books?filters=official&gameSystemSlug=grimdark-future-firefight&searchText=&page=1&unitCount=0&balanceValid=false&customRules=true&fans=false&sortBy=null")
#save_army_names_to_file(army_names, "")
fetch_army_data()

# Save upgrades to file
#save_to_file(upgrades_file_name, "Upgrades:\n", upgrades_as_strings)