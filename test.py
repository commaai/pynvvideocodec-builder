#!/usr/bin/env python3
import numpy as np
import PyNvVideoCodec as nvc
from openpilot.tools.lib.filereader import FileReader
from openpilot.tools.lib.framereader import get_index_data
from xx.datasets.helpers import load_route_list
from xx.common.basedir import XX_BASEPATH
from xx.chffr.lib.route import RouteSegment

def get_packets(fn: str, positions: np.ndarray):
    """Extract all packets from video file"""
    all_packets = [None for _ in range(len(positions) - 1)]
    with FileReader(fn) as f:
        data = f.read()
        for i in range(len(positions) - 1):
            all_packets[i] = data[positions[i]:positions[i+1]]
    return all_packets

def pnvc_packet(data: bytes) -> nvc.PacketData:
    """Create PyNvVideoCodec packet from bytes"""
    packet_data = nvc.PacketData()
    packet_data.bsl = len(data)
    packet_data.bsl_data = np.frombuffer(data, dtype=np.uint8).ctypes.data
    return packet_data

def main():
    segments = load_route_list(XX_BASEPATH / 'datasets/lists/train_500k_20240617_test_2k.txt')
    segment = RouteSegment(segments[0])

    print("DECODING...")
    index, header, w, h = get_index_data(segment.camera_url)
    frame_count = index.shape[0] - 1
    decoder = nvc.CreateDecoder(gpuid=0, codec=nvc.cudaVideoCodec.HEVC, usedevicememory=True)
    all_packets = get_packets(segment.camera_url, index[:, 1])
    for packet in [header] + all_packets + [b'']:
        for _ in decoder.Decode(pnvc_packet(packet)):
            pass
    print("SUCCESS")

if __name__ == "__main__":
    main()
