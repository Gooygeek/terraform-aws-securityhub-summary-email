import boto3
import os
import logging
import ast

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SINGLE_LINE_LENGTH = 80
DOUBLE_LINE_LENGTH = 47
FOOTER_TEXT = os.environ['AdditionalEmailFooterText']
HEADER_TEXT = os.environ['AdditionalEmailHeaderText']
TITLE_TEXT = 'Weekly Security Hub Report \n'
FOOTER_URL = 'https://console.aws.amazon.com/securityhub/home/standards#/standards'


# this function will add a horizontal line to the email
def add_horizontal_line(text_body, line_char, line_length):
    y = 0
    while y <= line_length:
        text_body += line_char
        y += 1
    text_body += '\n'

    return text_body


def lambda_handler(event, context):
    insightsMap = ast.literal_eval(os.environ['Insights'])
    insightLabelMap = {
        "aws_best_practices_by_status": "AWS Foundational Security Best Practices security checks:",
        "aws_best_practices_by_severity": "AWS Foundational Security Best Practices failed security checks by severity:",
        "cis_by_status": "CIS Benchmark Checks failed security checks:",
        "cis_by_severity": "CIS Benchmark Checks failed security checks by severity:",
        "guardduty_findings_by_severity": "GuardDuty threat detection findings by severity:",
        "iam_access_keys_by_severity": "IAM Access Analyzer findings by severity:",
        "all_findings_by_severity": "Unresolved findings by severity:",
        "new_findings": "New findings in the last 7 days:",
        "top_resource_types_with_findings_by_count": "Top 10 Resource Types with findings:"
    }
    #this is the placement number of insights that are grouped by severity, this is used for reversing the sort
    severityTypeInsights = [1, 2, 3, 4]

    #fetch the SNS arn to send the email body to, from lambda environment variables
    snsTopicArn = os.environ['SNSTopic']

    #determine region from the arns
    arnParsed = insightsMap[0][1].split(':')
    region = arnParsed[3]

    #format Email header
    snsBody = ''
    snsBody = add_horizontal_line(snsBody, '=', DOUBLE_LINE_LENGTH)
    snsBody += TITLE_TEXT
    snsBody = add_horizontal_line(snsBody, '=', DOUBLE_LINE_LENGTH)
    snsBody += '\n\n'
    if len(HEADER_TEXT) != 0:
        snsBody += HEADER_TEXT
        snsBody += '\n\n'

    #create boto3 client for Security Hub API calls
    sec_hub_client = boto3.client('securityhub')

    #for each custom insight get results and format for email
    i = 0
    for i in range(len(insightsMap)):
        #call security hub api to get results for each custom insight
        insightLabel = insightLabelMap[insightsMap[i][0]]
        response = sec_hub_client.get_insight_results(InsightArn=insightsMap[i][1])
        insightResults = response['InsightResults']['ResultValues']

        #format into an email - section header
        snsBody += str(insightLabel) + '\n'
        snsBody = add_horizontal_line(snsBody, '-', SINGLE_LINE_LENGTH)

        #check for blank custom insights
        if len(insightResults) == 0:
            snsBody += 'NO RESULTS \n'

        #determine how many rows are in this section, cap at 10
        totalRows = len(insightResults)
        if totalRows > 10:
            totalRows = 10

        #determine if this is the first section to customize the label
        if i == 0:
            firstSection = True
        else:
            firstSection = False

        # #determine if this is an insight that needs an updated sort
        # if (i in severityTypeInsights):
        #     #reverse the sort
        #     insightResults.reverse()

        #convert the API results into rows for email formatting
        x = 0
        while x < totalRows:

            snsBody += str(insightResults[x]['Count'])  #add the value
            snsBody += '\t - \t'  #add a divider
            if firstSection:  #add two extra labels (TOTAL and CHECKS) to the values for the foundational summary
                snsBody += 'TOTAL '
                snsBody += str(insightResults[x]['GroupByAttributeValue'])  #add the label
                snsBody += ' CHECKS'
            else:
                snsBody += str(insightResults[x]['GroupByAttributeValue'])  #add the label

            snsBody += '\n'  #next line
            x += 1

        #add table footer
        snsBody = add_horizontal_line(snsBody, '-', SINGLE_LINE_LENGTH)
        snsBody += ' \n'

        #create and add deep link for this section
        insightLink = 'https://' + region + '.console.aws.amazon.com/securityhub/home?region='
        insightLink += region + '#/insights/' + insightsMap[i][1]
        snsBody += insightLink

        snsBody += ' \n\n'
        i += 1

    #add footer text
    snsBody += FOOTER_TEXT
    snsBody += '\n'
    snsBody = add_horizontal_line(snsBody, '-', SINGLE_LINE_LENGTH)
    snsBody += FOOTER_URL

    #send to SNS
    sns_client = boto3.client('sns')

    response = sns_client.publish(TopicArn=snsTopicArn, Message=snsBody, Subject='Security Hub Summary Report')

    return {
        'statusCode': 200,
    }
