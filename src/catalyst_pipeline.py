from paraview.simple import *
from paraview import catalyst

# Greeting to ensure that ctest knows this script is being imported
print("executing catalyst_pipeline")

# registrationName must match the channel name used in the
# 'CatalystAdaptor'.
producer = TrivialProducer(registrationName="input")

options = catalyst.Options()
options.EnableCatalystLive = 1

def catalyst_execute(info):
    global producer
    global options

    print("-----------------------------------")
    print("executing (cycle={}, time={})".format(info.cycle, info.time))
    producer.UpdatePipeline()
    print("bounds:", producer.GetDataInformation().GetBounds())

    SaveExtractsUsingCatalystOptions(options)
