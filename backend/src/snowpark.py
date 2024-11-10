from flask import Blueprint, request, abort, make_response, jsonify
import datetime
import snowflake.snowpark.functions as f

import spcs_helpers
session = spcs_helpers.session()

# Make the API endpoints
snowpark = Blueprint('snowpark', __name__)

dateformat = '%Y-%m-%d'


def _build_cors_preflight_response():
    response = make_response()
    response.headers.add("Access-Control-Allow-Origin", "*")
    response.headers.add('Access-Control-Allow-Headers', "*")
    response.headers.add('Access-Control-Allow-Methods', "*")
    return response

def _corsify_actual_response(response):
    response.headers.add("Access-Control-Allow-Origin", "*")
    return response

## Top clerks in date range
@snowpark.route('/top_clerks')
def top_clerks():
    # Validate arguments
    sdt_str = request.args.get('start_range') or '1995-01-01'
    edt_str = request.args.get('end_range') or '1995-03-31'
    topn_str = request.args.get('topn') or '10'
    try:
        sdt = datetime.datetime.strptime(sdt_str, dateformat)
        edt = datetime.datetime.strptime(edt_str, dateformat)
        topn = int(topn_str)
    except:
        abort(400, "Invalid arguments.")
    try:
        df = session.sql("SELECT * FROM Reference('ORDERS_TABLE')") \
                .filter(f.col('O_ORDERDATE') >= sdt) \
                .filter(f.col('O_ORDERDATE') <= edt) \
                .group_by(f.col('O_CLERK')) \
                .agg(f.sum(f.col('O_TOTALPRICE')).as_('CLERK_TOTAL')) \
                .order_by(f.col('CLERK_TOTAL').desc()) \
                .limit(topn)
        return make_response(jsonify([x.as_dict() for x in df.to_local_iterator()]))
    except:
        abort(500, "Error reading from Snowflake. Check the logs for details.")


@snowpark.route('/ticks')
def ticks():
    # Validate arguments
    sdt_str = request.args.get('start_range') or '1995-01-01'
    edt_str = request.args.get('end_range') or '1995-03-31'
    topn_str = request.args.get('topn') or '10'
    try:
        sdt = datetime.datetime.strptime(sdt_str, dateformat)
        edt = datetime.datetime.strptime(edt_str, dateformat)
        topn = int(topn_str)
    except:
        abort(400, "Invalid arguments.")
    try:
        dfRef = session.sql("SELECT * FROM REFERENCE('TICKER_TABLE')")
        dfShared = session.sql("SELECT TICKER, DATE, LAST_PRICE FROM app_public.ticker_data")
        dfReturn = dfShared \
                .join(dfRef, "ticker") \
                .select(dfShared.TICKER, dfShared.DATE, dfShared.LAST_PRICE) \
                .limit(topn)
        return make_response(jsonify([x.as_dict() for x in dfReturn.to_local_iterator()]))
    except:
        abort(500, "Made a mess of the statement. Check the logs for details.")

@snowpark.route('/ticks2')
def ticks2():
    # Validate arguments
    ticker_str = request.args.get('ticker') or 'AMZN'
    try:
        ticker = str(ticker_str)
    except:
        abort(400, "Invalid arguments.")
    try:
        dfRef = session.sql("SELECT * FROM REFERENCE('TICKER_TABLE')")
        dfShared = session.sql("SELECT TICKER, DATE, AVG_PRICE, M_AVG FROM app_public.ticker_data")
        dfReturn = dfShared \
                .join(dfRef, "ticker") \
                .select(dfShared.TICKER, dfShared.DATE, dfShared.AVG_PRICE, dfShared.M_AVG) \
                .filter(dfShared.TICKER == ticker)
        return make_response(jsonify([x.as_dict() for x in dfReturn.to_local_iterator()]))
    except:
        abort(500, "Made a mess of the statement. Check the logs for details.")
    
@snowpark.route('/test', methods=["GET", "OPTIONS"])
def test():
        if request.method == "OPTIONS":
            return _build_cors_preflight_response()
        elif request.method == "GET": # The actual request following the preflight
            df = session.sql("SELECT AVG_PRICE, DATE , TICKER, M_AVG FROM TICKER_DATA")
            return _corsify_actual_response(make_response(jsonify([x.as_dict() for x in df.to_local_iterator()])))
        else:
            raise RuntimeError("Weird - don't know how to handle method {}".format(request.method))

@snowpark.route('/test2')
def test2():
    try:
        return make_response(jsonify(result='This is test2 correct'))
    except:
        return make_response(jsonify(result='This is test2 wrong'))
