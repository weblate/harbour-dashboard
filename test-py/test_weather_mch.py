# ~~ this file has no shebang because it must be run through run-py.sh ~~

import main as dash_main
from dashboard.util import log
import weather_mch


def main(base_path):
    dash_main.initialize(f'{base_path}/test-data/data', f'{base_path}/test-data/cache', f'{base_path}/test-data/config')

    # weather_mch.execute_command('get-search-suggestions', 0, 0, {'query': 'Bal'})
    # weather_mch.execute_command('get-weather-data', 0, 0, {'key': '300100'})
    weather_mch.execute_command('get-weather-data', 0, 0, {'key': '400100'})


if __name__ == '__main__':
    log('running as standalone script')
    main('.')
else:
    log('running as library')
    log('setup the main object by running:')
    log("""main('.')""")
