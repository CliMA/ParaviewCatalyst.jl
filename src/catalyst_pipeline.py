from paraview.simple import *
from paraview import catalyst

# registrationName must match the channel name used in the 'CatalystAdaptor'.
producer = TrivialProducer(registrationName="input")

options = catalyst.Options()
options.EnableCatalystLive = 1

def catalyst_execute(info):
    global producer
    global options

    print("-----------------------------------")
    print("executing (timestep={}, time={})".format(info.timestep, info.time))
    producer.UpdatePipeline()
    print("bounds:", producer.GetDataInformation().GetBounds())

    SaveExtractsUsingCatalystOptions(options)