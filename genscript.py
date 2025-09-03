import csv
import random
import string
from datetime import datetime, timedelta

# -----------------------------
# Helper Functions
# -----------------------------
def random_customer_id():
    return ''.join(random.choices(string.ascii_uppercase, k=8))

def random_policy_id(existing_ids):
    while True:
        pid = random.randint(100000, 999999)
        if pid not in existing_ids:
            existing_ids.add(pid)
            return pid

def random_claim_id(existing_ids):
    while True:
        cid = ''.join(random.choices(string.ascii_uppercase + string.digits, k=7))
        if cid not in existing_ids:
            existing_ids.add(cid)
            return cid

def random_name():
    first_names = ["John", "Sarah", "Michael", "Emily", "David", "Laura", "James", "Emma", "Daniel", "Sophia"]
    last_names = ["Smith", "Johnson", "Brown", "Williams", "Jones", "Garcia", "Miller", "Davis", "Lopez", "Wilson"]
    return random.choice(first_names) + " " + random.choice(last_names)

# -----------------------------
# Generate Table 1: Policies
# -----------------------------
navigation_areas = ["Chesapeake", "Great Lakes", "Gulf Coast", "New England", "Puget Sound", "South Atlantic", "West Coast"]
hull_materials = ["Aluminum", "Fiberglass", "Fiberglass over wood", "Inflatable", "Steel", "Wood"]

policy_ids = set()
customer_ids = []

policies = []
for _ in range(500):
    policy_id = random_policy_id(policy_ids)
    navigation_area = random.choice(navigation_areas)

    # Weighted hull materials (Wood <= 15%)
    hull = random.choices(
        hull_materials,
        weights=[25, 25, 15, 10, 15, 10],  # Aluminum/Fiberglass more common
        k=1
    )[0]

    # Coverage limit distribution
    coverage = random.randint(30000, 300000)
    if coverage > 200000:
        coverage = random.randint(200001, 300000) if random.random() < 0.2 else random.randint(30000, 200000)

    # Annual premium correlation
    premium = int(coverage / random.uniform(40, 60))

    # Year built distribution
    year_built = random.choices(
        range(1920, 2026),
        weights=[1 if 1920 <= y <= 1960 else 2 if 1961 <= y <= 1989 else 7 for y in range(1920, 2026)],
        k=1
    )[0]

    # Customer IDs (with repeats allowed)
    if len(customer_ids) < 450 or random.random() < 0.15:
        cust_id = random_customer_id()
        customer_ids.append(cust_id)
    else:
        cust_id = random.choice(customer_ids)

    policies.append([policy_id, navigation_area, hull, coverage, premium, year_built, cust_id])

# Write CSV
with open("policies.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Policy_ID", "Navigation_Area", "Hull_Material", "Coverage_Limit", "Annual_Premium", "Year_Boat_Built", "Customer_ID"])
    writer.writerows(policies)

# -----------------------------
# Generate Table 2: Claims
# -----------------------------
causes = ["Striking Submerged Object", "Hurricane", "Collision", "Sinking", "Grounding"]

claim_ids = set()
claims = []

policy_sample = random.sample(policies, 150)
for policy in policy_sample:
    policy_id = policy[0]
    coverage = policy[3]

    claim_id = random_claim_id(claim_ids)

    # Claim date (more in summer/fall, cluster in July)
    month_weights = [1,1,1,2,3,6,10,8,6,4,2,1]
    month = random.choices(range(1,13), weights=month_weights, k=1)[0]
    day = random.randint(1,28)
    claim_date = datetime(2023, month, day).strftime("%Y-%m-%d")

    # Cause of loss
    cause = random.choice(causes)
    if month == 7:
        cause = random.choices(causes, weights=[5,15,5,2,5], k=1)[0]

    # Claim payment
    if cause == "Sinking":
        payment = coverage
    elif random.random() < 0.25:
        payment = coverage  # Full coverage payout
    else:
        payment = int(coverage * random.uniform(0.1, 0.3))

    claims.append([claim_id, claim_date, payment, cause, policy_id])

with open("claims.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Claim_ID", "Claim_Date", "Claim_Payment", "Cause_of_Loss", "Policy_ID"])
    writer.writerows(claims)

# -----------------------------
# Generate Table 3: Customers
# -----------------------------
unique_customers = list(set([p[6] for p in policies]))
customers = []

for cust_id in unique_customers:
    name = random_name()
    age = random.choices(range(30,71), weights=[2 if 50 <= a <= 70 else 1 for a in range(30,71)], k=1)[0]
    operator_exp = "Yes" if random.random() < 0.85 else "No"
    multi_policy = "Yes" if random.random() < 0.25 else "No"
    years_insured = random.choices(range(0,11), weights=[5 if y <= 3 else 2 if y <= 5 else 1 for y in range(0,11)], k=1)[0]
    income_band = random.choice(["Low", "Medium", "High"])
    customers.append([cust_id, name, age, operator_exp, multi_policy, years_insured, income_band])

with open("customers.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["Customer_ID", "Name", "Age", "Operator_Experience", "Multi-Policy", "Years_Insured", "Income_Band"])
    writer.writerows(customers)

print("✅ CSV files generated: policies.csv, claims.csv, customers.csv")
