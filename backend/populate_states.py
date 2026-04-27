import sqlite3

conn = sqlite3.connect(r'D:\AgroAssist\AgroAssist\backend\db.sqlite3')
cursor = conn.cursor()

crop_states = {
    'Arhar': 'Maharashtra,Uttar Pradesh,Madhya Pradesh,Karnataka',
    'Bajra': 'Rajasthan,Maharashtra,Gujarat,Uttar Pradesh,Haryana',
    'Banana': 'Maharashtra,Tamil Nadu,Andhra Pradesh,Karnataka,Gujarat',
    'Barley BH-902': 'Rajasthan,Uttar Pradesh,Haryana,Punjab,Himachal Pradesh',
    'Barley Pusa Losar (BH- 380)': 'Rajasthan,Uttar Pradesh,Haryana,Punjab',
    'Rice': 'West Bengal,Uttar Pradesh,Punjab,Andhra Pradesh,Tamil Nadu',
    'Wheat': 'Punjab,Haryana,Uttar Pradesh,Madhya Pradesh,Rajasthan',
    'Cotton': 'Maharashtra,Gujarat,Andhra Pradesh,Haryana,Punjab',
    'Sugarcane': 'Uttar Pradesh,Maharashtra,Karnataka,Tamil Nadu',
    'Maize': 'Karnataka,Andhra Pradesh,Rajasthan,Maharashtra,Uttar Pradesh',
    'Groundnut': 'Gujarat,Andhra Pradesh,Tamil Nadu,Karnataka,Rajasthan',
    'Soybean': 'Madhya Pradesh,Maharashtra,Rajasthan,Karnataka',
    'Sunflower': 'Karnataka,Andhra Pradesh,Maharashtra,Tamil Nadu',
    'Mustard': 'Rajasthan,Haryana,Uttar Pradesh,Madhya Pradesh,Punjab',
    'Onion': 'Maharashtra,Madhya Pradesh,Karnataka,Gujarat,Bihar',
    'Tomato': 'Andhra Pradesh,Maharashtra,Karnataka,Odisha,Gujarat',
    'Potato': 'Uttar Pradesh,West Bengal,Bihar,Punjab,Gujarat',
    'Chilli': 'Andhra Pradesh,Maharashtra,Karnataka,Tamil Nadu,Rajasthan',
    'Jowar': 'Maharashtra,Karnataka,Rajasthan,Andhra Pradesh,Madhya Pradesh',
    'Tur': 'Maharashtra,Karnataka,Uttar Pradesh,Madhya Pradesh,Gujarat',
    'Moong': 'Rajasthan,Maharashtra,Andhra Pradesh,Karnataka,Uttar Pradesh',
    'Urad': 'Uttar Pradesh,Madhya Pradesh,Andhra Pradesh,Tamil Nadu,Maharashtra',
    'Lentil': 'Uttar Pradesh,Madhya Pradesh,Bihar,Rajasthan,West Bengal',
    'Gram': 'Madhya Pradesh,Rajasthan,Uttar Pradesh,Maharashtra,Andhra Pradesh',
    'Pea': 'Uttar Pradesh,Madhya Pradesh,Bihar,Himachal Pradesh,Punjab',
    'Linseed': 'Madhya Pradesh,Uttar Pradesh,Maharashtra,Bihar,Chhattisgarh',
    'Safflower': 'Maharashtra,Karnataka,Andhra Pradesh,Madhya Pradesh,Rajasthan',
    'Castor': 'Gujarat,Rajasthan,Andhra Pradesh,Karnataka,Odisha',
    'Sesamum': 'Uttar Pradesh,Rajasthan,Gujarat,Madhya Pradesh,West Bengal',
    'Turmeric': 'Andhra Pradesh,Tamil Nadu,Odisha,Karnataka,West Bengal',
    'Ginger': 'Kerala,Meghalaya,Sikkim,Arunachal Pradesh,Himachal Pradesh',
    'Garlic': 'Madhya Pradesh,Gujarat,Rajasthan,Uttar Pradesh,Maharashtra',
    'Brinjal': 'West Bengal,Odisha,Bihar,Gujarat,Maharashtra',
    'Cabbage': 'West Bengal,Odisha,Bihar,Assam,Maharashtra',
    'Cauliflower': 'West Bengal,Bihar,Odisha,Punjab,Haryana',
    'Pumpkin': 'West Bengal,Bihar,Odisha,Maharashtra,Uttar Pradesh',
    'Cucumber': 'Maharashtra,Karnataka,Andhra Pradesh,Tamil Nadu,Gujarat',
    'Watermelon': 'Andhra Pradesh,Tamil Nadu,Karnataka,Maharashtra,Rajasthan',
    'Mango': 'Uttar Pradesh,Andhra Pradesh,Karnataka,Bihar,Gujarat',
    'Papaya': 'Andhra Pradesh,Gujarat,Maharashtra,Karnataka,Tamil Nadu',
    'Guava': 'Uttar Pradesh,Maharashtra,Bihar,Gujarat,Andhra Pradesh',
    'Pomegranate': 'Maharashtra,Gujarat,Rajasthan,Karnataka,Andhra Pradesh',
    'Coconut': 'Kerala,Tamil Nadu,Karnataka,Andhra Pradesh,Goa',
    'Jute': 'West Bengal,Bihar,Assam,Odisha,Meghalaya',
}

cursor.execute('SELECT id, name, season FROM crops_crop')
crops = cursor.fetchall()

updated = 0
for crop_id, name, season in crops:
    states = crop_states.get(name)
    if not states:
        if season == 'Kharif':
            states = 'Maharashtra,Madhya Pradesh,Karnataka,Andhra Pradesh,Gujarat'
        elif season == 'Rabi':
            states = 'Punjab,Haryana,Uttar Pradesh,Rajasthan,Madhya Pradesh'
        elif season == 'Summer':
            states = 'Gujarat,Maharashtra,Rajasthan,Tamil Nadu,Karnataka'
        else:
            states = 'Maharashtra,Punjab,Uttar Pradesh'
    cursor.execute('UPDATE crops_crop SET states = ? WHERE id = ?', (states, crop_id))
    updated += 1
    print('Updated: ' + name + ' -> ' + states[:40])

conn.commit()

cursor.execute('SELECT COUNT(*) FROM crops_crop WHERE states != ""')
count = cursor.fetchone()[0]
print('Done! ' + str(count) + '/79 crops now have states.')

all_states = set()
cursor.execute('SELECT states FROM crops_crop WHERE states != ""')
for (s,) in cursor.fetchall():
    for state in s.split(','):
        state = state.strip()
        if state:
            all_states.add(state)

print('Total unique states: ' + str(len(all_states)))
print(sorted(all_states))
conn.close()
