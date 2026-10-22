project(tools VERSION 1.0.0)

find_package(Curses REQUIRED)

# cyber monitor
add_executable(cyber_monitor
  cyber_monitor/cyber_topology_message.cc
  cyber_monitor/general_channel_message.cc
  cyber_monitor/general_message.cc
  cyber_monitor/general_message_base.cc
  cyber_monitor/renderable_message.cc
  cyber_monitor/screen.cc
  cyber_monitor/main.cc
)
target_link_libraries(cyber_monitor
  pthread
  ncurses
  ${TARGET_NAME}
)
set_target_properties(cyber_monitor PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/cyber/tools/cyber_monitor/"
)

# cyber_recorder
add_executable(cyber_recorder
  cyber_recorder/main.cc
  cyber_recorder/info.cc
  cyber_recorder/recorder.cc
  cyber_recorder/recoverer.cc
  cyber_recorder/spliter.cc
  cyber_recorder/player/play_task.cc
  cyber_recorder/player/play_task_buffer.cc
  cyber_recorder/player/play_task_consumer.cc
  cyber_recorder/player/play_task_producer.cc
  cyber_recorder/player/player.cc
)
target_link_libraries(cyber_recorder
 ${TARGET_NAME}
)
set_target_properties(cyber_recorder PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/cyber/tools/cyber_recorder/"
)

# Keep Python sources as .py files and invoke them through Python explicitly.
foreach(tool cyber_channel cyber_launch cyber_node cyber_service)
  set(tool_dir "${CMAKE_BINARY_DIR}/bin/cyber/tools/${tool}")
  file(MAKE_DIRECTORY "${tool_dir}")
  set(CYBER_TOOL_SCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/${tool}/${tool}.py")
  configure_file(python_tool.sh.in "${tool_dir}/${tool}" @ONLY)
  file(CHMOD "${tool_dir}/${tool}" PERMISSIONS
    OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

  # Installed launchers resolve their companion script relative to themselves.
  set(CYBER_TOOL_SCRIPT "\$(dirname \"\$0\")/${tool}.py")
  configure_file(python_tool.sh.in "${tool_dir}/installed/${tool}" @ONLY)
  install(PROGRAMS "${tool_dir}/installed/${tool}" DESTINATION bin)
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/${tool}/${tool}.py" DESTINATION bin)
endforeach()

file(COPY cyber_tools_auto_complete.bash DESTINATION ${CMAKE_BINARY_DIR})
install(PROGRAMS
  ${CMAKE_BINARY_DIR}/bin/cyber/tools/cyber_monitor/cyber_monitor
  ${CMAKE_BINARY_DIR}/bin/cyber/tools/cyber_recorder/cyber_recorder
  DESTINATION bin
)
install(FILES
  ${CMAKE_BINARY_DIR}/cyber_tools_auto_complete.bash
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
  DESTINATION .
)
