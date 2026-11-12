"""Rebuild SQLite and export each named query as CSV. Standard library only."""
import csv
import sqlite3
from datetime import date
from decimal import Decimal
from pathlib import Path
from tempfile import TemporaryDirectory

ROOT = Path(__file__).resolve().parent
DATA = ROOT / 'data'
SQL = ROOT / 'sql'

# Source headers in destination column order, with explicit type conversion.
def cents(value):
    scaled = Decimal(value) * 100
    if scaled != scaled.to_integral_value():
        raise ValueError('Unexpected sub-cent value: ' + value)
    return int(scaled)


def iso_date(value):
    return date.fromisoformat(value).isoformat()


def required_text(value):
    if not value or not value.strip():
        raise ValueError('Missing required text')
    return value


TABLES = [
    ('Factories', [('Factory', required_text), ('Latitude', float), ('Longitude', float)]),
    ('Targets', [('Division', required_text), ('Target', cents)]),
    ('Products', [('Product ID', required_text), ('Product Name', required_text),
                  ('Division', required_text), ('Factory', required_text),
                  ('Unit Price', cents), ('Unit Cost', cents)]),
    ('Sales', [('Row ID', int), ('Order ID', required_text), ('Order Date', iso_date),
               ('Ship Date', iso_date), ('Ship Mode', required_text), ('Customer ID', int),
               ('Country/Region', required_text), ('City', required_text),
               ('State/Province', required_text), ('Postal Code', required_text),
               ('Division', required_text), ('Region', required_text),
               ('Product ID', required_text), ('Product Name', required_text),
               ('Sales', cents), ('Units', int), ('Gross Profit', cents), ('Cost', cents)]),
]


def import_table(db, name, columns):
    with (DATA / ('Candy_' + name + '.csv')).open(encoding='utf-8-sig', newline='') as source:
        rows = csv.DictReader(source)
        if set(rows.fieldnames or ()) != {field for field, _ in columns}:
            raise ValueError('Unexpected CSV headers: ' + name)
        placeholders = ', '.join('?' for _ in columns)
        db.executemany(
            'INSERT INTO candy_{} VALUES ({})'.format(name.lower(), placeholders),
            (tuple(convert(row[field]) for field, convert in columns) for row in rows),
        )


def export(cursor, path):
    with path.open('w', encoding='utf-8', newline='') as file:
        writer = csv.writer(file)
        writer.writerow([column[0] for column in cursor.description])
        writer.writerows(cursor)


def build():
    destination = ROOT / 'results'
    destination.mkdir(exist_ok=True)
    with TemporaryDirectory(dir=str(ROOT)) as temp:
        folder = Path(temp)
        database = folder / 'candy.sqlite'
        db = sqlite3.connect(str(database))
        try:
            db.executescript((SQL / 'schema.sql').read_text(encoding='utf-8'))
            with db:
                for name, columns in TABLES:
                    import_table(db, name, columns)
                quality_sql = (SQL / 'quality.sql').read_text(encoding='utf-8')
                quality = dict(db.execute(quality_sql))
                expected = {
                    'total_sales_lines': 10194, 'distinct_order_ids': 8549,
                    'distinct_customers': 5044, 'us_lines': 9994, 'canada_lines': 200,
                    'products': 15, 'factories': 5, 'target_rows': 3, 'divisions': 3,
                    'foreign_key_violations': 0, 'integrity_errors': 0, 'duplicate_row_ids': 0,
                }
                for check, value in expected.items():
                    if quality[check] != value:
                        raise ValueError('{}: expected {}, got {}'.format(check, value, quality[check]))
                export(db.execute(quality_sql), folder / 'quality.csv')
                queries = (SQL / 'analysis.sql').read_text(encoding='utf-8')
                for block in queries.split('-- output: ')[1:]:
                    name, query = block.split('\n', 1)
                    export(db.execute(query), folder / (name + '.csv'))
        finally:
            db.close()
        database.replace(ROOT / database.name)
        for result in folder.glob('*.csv'):
            result.replace(destination / result.name)
    print('Built candy.sqlite and exported results/*.csv')


if __name__ == '__main__':
    build()

