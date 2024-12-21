CXX = g++
CXXFLAGS = -Wall -std=c++11
TARGET = FuncClass
SOURCES = main.cpp FuncClass.cpp
OBJECTS = $(SOURCES:.cpp=.o)
all: $(TARGET)
$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) -o $(TARGET)
%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@
clean:
	rm -f $(OBJECTS) $(TARGET)
.PHONY: all clean