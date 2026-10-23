// Contract: current Apollo DDS envelope is int32/int32/string/string.
// Compile with APOLLO_LEGACY_RTPS and link fastcdr plus underlay_message.cc.
#include <cassert>
#include <cstring>
#include <string>
#include <fastcdr/Cdr.h>
#include <fastcdr/FastBuffer.h>
#include "cyber/transport/rtps/underlay_message.h"
int main() {
  using eprosima::fastcdr::Cdr;
  using eprosima::fastcdr::FastBuffer;
  using apollo::cyber::transport::UnderlayMessage;
  for (const std::string data : {std::string(), std::string("hello"), std::string("a\0b", 3), std::string(2048, 'x')}) {
    char actual[8192] = {}, expected[8192] = {};
    FastBuffer a(actual, sizeof(actual)), e(expected, sizeof(expected));
    Cdr writer(a, Cdr::DEFAULT_ENDIAN, eprosima::fastcdr::CdrVersion::DDS_CDR);
    Cdr oracle(e, Cdr::DEFAULT_ENDIAN, eprosima::fastcdr::CdrVersion::DDS_CDR);
    UnderlayMessage message;
    message.timestamp(123); message.seq(456); message.data(data);
    message.serialize(writer);
    oracle << int32_t(123) << int32_t(456) << data << std::string();
    assert(writer.get_serialized_data_length() == oracle.get_serialized_data_length());
    assert(std::memcmp(actual, expected, writer.get_serialized_data_length()) == 0);
    assert(message.getCdrSerializedSize(message) == writer.get_serialized_data_length());
    // Read an Apollo envelope with a nonempty legacy datatype field.
    Cdr incoming(e, Cdr::DEFAULT_ENDIAN, eprosima::fastcdr::CdrVersion::DDS_CDR);
    incoming << int32_t(12) << int32_t(34) << data << std::string("legacy");
    Cdr reader(e, Cdr::DEFAULT_ENDIAN, eprosima::fastcdr::CdrVersion::DDS_CDR);
    UnderlayMessage decoded; decoded.deserialize(reader);
    assert(decoded.timestamp() == 12 && decoded.seq() == 34 && decoded.data() == data);
  }
}
