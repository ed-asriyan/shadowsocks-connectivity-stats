FROM python:3.11
RUN apt update && apt install -y graphviz

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY cli.py .

CMD ./cli.py --input /input.csv
