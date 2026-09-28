#include "google/cloud/aiplatform/v1/prediction_client.h"
#include "google/cloud/location.h"

namespace vertex_ai = ::google::cloud::aiplatform_v1;
namespace vertex_ai_proto = ::google::cloud::aiplatform::v1;

void GenerateText(std::string const& project_id,
                  std::string const& location_id,
                  std::string const& model,
                  std::vector<std::string> const& prompts) {
  google::cloud::Location location(project_id, location_id);
  auto client = vertex_ai::PredictionServiceClient(
      vertex_ai::MakePredictionServiceConnection(location.location_id()));

  std::vector<vertex_ai_proto::Content> contents;
  for (auto const& text : prompts) {
    vertex_ai_proto::Content content;
    content.set_role("user");
    content.add_parts()->set_text(text);
    contents.push_back(std::move(content));
  }

  auto response = client.GenerateContent(
      location.FullName() + "/publishers/google/models/" + model, contents);

  if (!response) throw std::move(response).status();

  for (auto const& candidate : response->candidates()) {
    for (auto const& part : candidate.content().parts()) {
      std::cout << part.text() << "\n";
    }
  }
}