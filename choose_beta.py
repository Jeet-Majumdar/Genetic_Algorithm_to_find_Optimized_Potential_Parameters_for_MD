import numpy as np
import random

n = 50

mu = random.uniform(0, 1)

beta = 0

if mu <= 0.5:
	beta = (2.0 * mu)**(1.0/(n + 1))
else:
	beta = (0.5/(1-mu))**(1.0/(n + 1))

print(beta)

