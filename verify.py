"""Cross-check published SQL outputs against independent CSV aggregates."""
import csv
import sqlite3
from collections import defaultdict
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def read(path):
    with (ROOT / path).open(encoding='utf-8-sig', newline='') as file:
        return list(csv.DictReader(file))


def require(condition, message):
    if not condition:
        raise ValueError(message)


def verify_exports():
    catalog = {row['Product ID']: row for row in read('data/Candy_Products.csv')}
    us = [row for row in read('data/Candy_Sales.csv') if row['Country/Region'] == 'United States']
    groups = {
        'overview': (None, lambda row: None),
        'annual': ('year', lambda row: row['Order Date'][:4]),
        'monthly': ('month', lambda row: row['Order Date'][:7]),
        'divisions': ('division', lambda row: catalog[row['Product ID']]['Division']),
        'products': ('product_id', lambda row: row['Product ID']),
        'states': ('state', lambda row: row['State/Province']),
    }
    for name, (key, group_by) in groups.items():
        expected = defaultdict(list)
        for row in us:
            expected[group_by(row)].append(row)
        exported = read('results/' + name + '.csv')
        require(len(exported) == len(expected), 'Unexpected result count in ' + name)
        for actual in exported:
            lines = expected.pop(actual.get(key))
            revenue = sum(Decimal(row['Sales']) for row in lines)
            profit = sum(Decimal(row['Gross Profit']) for row in lines)
            margin = (100 * profit / revenue).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
            metrics = {
                'revenue': revenue, 'gross_profit': profit, 'gross_margin_pct': margin,
                'order_ids': len({row['Order ID'] for row in lines}),
                'units': sum(int(row['Units']) for row in lines),
                'sales_lines': len(lines), 'customers': len({row['Customer ID'] for row in lines}),
                'manufacturing_cost': sum(Decimal(row['Cost']) for row in lines),
            }
            for field, value in metrics.items():
                if field in actual:
                    require(Decimal(actual[field]) == value,
                            '{} {}: {} differs from source'.format(name, actual.get(key), field))
    annual = read('results/annual.csv')
    require([row['year'] for row in annual] == ['2021', '2022', '2023', '2024'], 'Annual coverage')
    require(annual[0]['revenue_yoy_pct'] == '', 'First year has no prior-year growth')
    for prior, current in zip(annual, annual[1:]):
        before, after = Decimal(prior['revenue']), Decimal(current['revenue'])
        yoy = (100 * (after - before) / before).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
        require(Decimal(current['revenue_yoy_pct']) == yoy, 'Annual YoY mismatch')


def verify_constraints():
    with sqlite3.connect(':memory:') as db:
        db.executescript((ROOT / 'sql' / 'schema.sql').read_text(encoding='utf-8'))
        db.execute("INSERT INTO candy_factories VALUES ('Sample', 0, 0)")
        invalid = [
            ("INSERT INTO candy_factories VALUES ('Sample', 0, 0)", 'UNIQUE'),
            ("INSERT INTO candy_products VALUES ('P', 'Product', 'Other', 'Missing', 100, 50)", 'FOREIGN KEY'),
        ]
        for statement, constraint in invalid:
            try:
                db.execute(statement)
            except sqlite3.IntegrityError as error:
                require(constraint in str(error), str(error))
            else:
                raise ValueError('Expected rejection: ' + constraint)


if __name__ == '__main__':
    verify_exports()
    verify_constraints()
    print('Verified six SQL exports against source CSVs and confirmed PK/FK rejection.')

