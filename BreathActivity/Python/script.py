import time
a = 0
def test():
  while True:
    a += 1
    time.sleep(1)
    print(f'{a}')
