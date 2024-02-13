# ~~ this file has no shebang because it must be run through run-py.sh ~~

import main as dash_main
from dashboard.util import log
import weather_mch


def main(base_path):
    dash_main.initialize(f'{base_path}/test-data/data', f'{base_path}/test-data/cache', f'{base_path}/test-data/config')

    weather_mch.execute_command('', 0, 0, {})


if __name__ == '__main__':
    log('running as standalone script')
    main('.')
else:
    log('running as library')
    log('setup the main object by running:')
    log("""main('.')""")
